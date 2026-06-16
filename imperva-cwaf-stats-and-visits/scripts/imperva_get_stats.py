#!/usr/bin/env python3
"""
Imperva CWAF — Statistics & Visits

Usage:
  SITE_ID=<id> CAID=<caid> bws run --project-id <bw_id> -- python3 imperva_get_stats.py [command] [options]

Commands:
  stats       Fetch site statistics (/api/stats/v1)
  visits      Fetch visit sessions (/api/visits/v1) with client-side filtering

Output formats:
  --format table   Rich visual output with box-drawing, emoji, bar charts (default)
  --format json    Raw JSON (for agent/programmatic use)
  --format report  Analysis report with aggregate stats + suggested actions (visits only)

Examples:
  # Stats: threats summary
  SITE_ID=852056322 CAID=2429928 bws run --project-id <id> -- python3 imperva_get_stats.py stats --stats threats

  # Visits: filter by incident ID
  SITE_ID=852056322 CAID=2429928 bws run --project-id <id> -- python3 imperva_get_stats.py visits --incident-id 526000340320036642-169334527402838191

  # Visits: find .git probes with analysis report
  SITE_ID=852056322 CAID=2429928 bws run --project-id <id> -- python3 imperva_get_stats.py visits --filter-path ".git" --format report
"""

import argparse
import json
import os
import sys
import time
from datetime import datetime, timedelta, timezone
from collections import Counter

try:
    import requests
except ImportError:
    print("ERROR: 'requests' module not found. Install with: pip install requests", file=sys.stderr)
    sys.exit(1)

BASE_URL = "https://my.imperva.com"
MAX_RETRIES = 4
RETRY_DELAYS = [5, 15, 30, 60]

VALID_STATS = [
    "visits_timeseries", "hits_timeseries", "bandwidth_timeseries",
    "requests_geo_dist_summary", "visits_dist_summary", "caching",
    "caching_timeseries", "threats", "incap_rules", "incap_rules_timeseries",
    "delivery_rules", "delivery_rules_timeseries",
]

VALID_TIME_RANGES = [
    "today", "last_7_days", "last_30_days", "last_90_days",
    "month_to_date", "custom",
]


# ── Helpers ──────────────────────────────────────────────────────────────────

def get_credentials():
    api_id = os.environ.get("IMPERVA_API_ID")
    api_key = os.environ.get("IMPERVA_API_KEY")
    if not api_id or not api_key:
        print("ERROR: IMPERVA_API_ID and IMPERVA_API_KEY must be set (injected by bws run)", file=sys.stderr)
        sys.exit(1)
    return api_id, api_key


def get_identifiers(args):
    site_id = getattr(args, 'site_id', None) or os.environ.get("SITE_ID")
    caid = getattr(args, 'caid', None) or os.environ.get("CAID")
    if not site_id:
        print("ERROR: SITE_ID must be set via --site-id or SITE_ID env var", file=sys.stderr)
        sys.exit(1)
    return site_id, caid


def parse_incident_id(incident_id_str):
    """Extract visit_id from incident_id format: <visit_id>-<incident_number>"""
    if not incident_id_str:
        return None
    parts = incident_id_str.strip().split("-", 1)
    if len(parts) == 2 and parts[0].isdigit():
        return parts[0]
    if incident_id_str.strip().isdigit():
        return incident_id_str.strip()
    return None


def api_post(path, params, api_id, api_key, retry=True):
    url = f"{BASE_URL}{path}"
    headers = {
        "Accept": "application/json",
        "x-API-Id": api_id,
        "x-API-Key": api_key,
    }
    data = None
    for attempt in range(MAX_RETRIES if retry else 1):
        try:
            resp = requests.post(url, headers=headers, params=params, timeout=30)
            data = resp.json()
            res_code = data.get("res") if isinstance(data, dict) else None
            if res_code == 15 and attempt < MAX_RETRIES - 1:
                delay = RETRY_DELAYS[attempt]
                print(f"  [WAF block — retry in {delay}s...]", file=sys.stderr)
                time.sleep(delay)
                continue
            return data
        except requests.exceptions.Timeout:
            if attempt < MAX_RETRIES - 1:
                delay = RETRY_DELAYS[attempt]
                print(f"  [Timeout — retry in {delay}s...]", file=sys.stderr)
                time.sleep(delay)
            else:
                raise
        except requests.exceptions.ConnectionError:
            if attempt < MAX_RETRIES - 1:
                delay = RETRY_DELAYS[attempt]
                print(f"  [Connection error — retry in {delay}s...]", file=sys.stderr)
                time.sleep(delay)
            else:
                raise
    return data


def ts_to_iso(ts_ms):
    if not ts_ms:
        return "N/A"
    try:
        dt = datetime.fromtimestamp(int(ts_ms) / 1000, tz=timezone.utc)
        return dt.strftime("%Y-%m-%d %H:%M:%S UTC")
    except (ValueError, OSError, TypeError):
        return str(ts_ms)


def ts_to_short(ts_ms):
    if not ts_ms:
        return "N/A"
    try:
        dt = datetime.fromtimestamp(int(ts_ms) / 1000, tz=timezone.utc)
        return dt.strftime("%m-%d %H:%M")
    except (ValueError, OSError, TypeError):
        return str(ts_ms)


def fmt_bytes(num):
    try:
        n = int(num)
        for unit in ["B", "KB", "MB", "GB", "TB"]:
            if abs(n) < 1024:
                return f"{n:.1f} {unit}"
            n /= 1024
        return f"{n:.1f} PB"
    except (ValueError, TypeError):
        return str(num)


def fmt_number(num):
    try:
        return f"{int(num):,}"
    except (ValueError, TypeError):
        return str(num)


# ── Client-side visit filters ────────────────────────────────────────────────

def apply_client_side_filters(visits, args):
    """Apply client-side filters to visit list. Returns filtered list."""
    filtered = visits

    ftype = getattr(args, 'filter_type', None)
    if ftype:
        filtered = [v for v in filtered if ftype.lower() in v.get("clientType", "").lower()]

    fapp = getattr(args, 'filter_app', None)
    if fapp:
        filtered = [v for v in filtered if fapp.lower() in v.get("clientApplication", "").lower()]

    fpath = getattr(args, 'filter_path', None)
    if fpath:
        pattern = fpath.lower()
        result = []
        for v in filtered:
            if pattern in v.get("entryPage", "").lower():
                result.append(v)
                continue
            for a in v.get("actions", []):
                if pattern in a.get("url", "").lower():
                    result.append(v)
                    break
        filtered = result

    fresult = getattr(args, 'filter_result', None)
    if fresult:
        pattern = fresult.lower()
        result = []
        for v in filtered:
            for a in v.get("actions", []):
                if pattern in a.get("requestResult", "").lower():
                    result.append(v)
                    break
        filtered = result

    fcode = getattr(args, 'filter_attack_code', None)
    if fcode:
        result = []
        for v in filtered:
            for a in v.get("actions", []):
                for t in a.get("threats", []):
                    if fcode in str(t.get("attackCodes", [])):
                        result.append(v)
                        break
        filtered = result

    fua = getattr(args, 'filter_ua', None)
    if fua:
        pattern = fua.lower()
        filtered = [v for v in filtered if pattern in v.get("userAgent", "").lower()]

    fpop = getattr(args, 'filter_pop', None)
    if fpop:
        pattern = fpop.lower()
        result = []
        for v in filtered:
            for sv in v.get("servedVia", []):
                if pattern in str(sv).lower():
                    result.append(v)
                    break
        filtered = result

    fsec = getattr(args, 'filter_security_rule', None)
    if fsec:
        pattern = fsec.lower()
        result = []
        for v in filtered:
            sec = v.get("security_summary", {})
            if isinstance(sec, dict):
                for k in sec:
                    if pattern in k.lower():
                        result.append(v)
                        break
            if v not in result:
                for a in v.get("actions", []):
                    for t in a.get("threats", []):
                        if pattern in t.get("securityRule", "").lower():
                            result.append(v)
                            break
        filtered = result

    return filtered


# ── Analysis report ──────────────────────────────────────────────────────────

def generate_analysis_report(visits, filtered, args):
    """Generate analysis report for filtered visits."""
    W = 78

    total_fetched = len(visits)
    total_matched = len(filtered)

    country_counter = Counter()
    type_counter = Counter()
    app_counter = Counter()
    result_counter = Counter()
    rule_counter = Counter()
    attack_code_counter = Counter()
    pop_counter = Counter()
    path_counter = Counter()

    all_blocked = True
    has_actions = False

    for v in filtered:
        for c in v.get("country", []):
            country_counter[c] += 1
        type_counter[v.get("clientType", "Unknown")] += 1
        app_counter[v.get("clientApplication", "Unknown")] += 1
        for sv in v.get("servedVia", []):
            pop_counter[sv] += 1
        for a in v.get("actions", []):
            has_actions = True
            result = a.get("requestResult", "")
            result_counter[result] += 1
            url = a.get("url", "")
            path_counter[url] += 1
            for t in a.get("threats", []):
                rule = t.get("securityRule", "unknown")
                rule_counter[rule] += 1
                for code in t.get("attackCodes", []):
                    attack_code_counter[str(code)] += 1
        for a in v.get("actions", []):
            res = a.get("requestResult", "")
            if "block" not in res.lower() and "challenge" not in res.lower():
                all_blocked = False

    print()
    print("┌" + "─" * W + "┐")
    print("│" + " 🔍 SESSION LOG ANALYSIS REPORT ".center(W) + "│")
    print("├" + "─" * W + "┤")

    # Filter conditions
    print("│" + " FILTER CONDITIONS".ljust(W) + "│")
    print("│" + " " + "─" * (W-4) + " │")

    filter_lines = []
    for attr, label in [
        ('country', 'Country'), ('ip', 'IP'), ('visit_id', 'Visit ID'),
        ('incident_id', 'Incident ID'), ('security', 'Security'),
        ('time_range', 'Time Range'), ('filter_type', 'Client Type'),
        ('filter_app', 'Client App'), ('filter_path', 'Path Contains'),
        ('filter_result', 'Request Result'), ('filter_attack_code', 'Attack Code'),
        ('filter_ua', 'UA Contains'), ('filter_pop', 'PoP Contains'),
        ('filter_security_rule', 'Security Rule'),
    ]:
        val = getattr(args, attr, None)
        if val:
            filter_lines.append(f"{label}: {val}")

    if filter_lines:
        for fl in filter_lines:
            print("│" + f"   • {fl}"[:W].ljust(W) + "│")
    else:
        print("│" + "   (none — showing all)".ljust(W) + "│")

    print("├" + "─" * W + "┤")

    # Results summary
    print("│" + " RESULTS".ljust(W) + "│")
    print("│" + " " + "─" * (W-4) + " │")
    print("│" + f"   Total fetched:  {total_fetched:>6}  |  Matched: {total_matched:>6}"[:W].ljust(W) + "│")
    if total_fetched > 0:
        pct = total_matched / total_fetched * 100
        print("│" + f"   Match rate:     {pct:>5.1f}%"[:W].ljust(W) + "│")
    blocked_str = "✅ Yes" if all_blocked and has_actions else ("❌ No" if has_actions else "N/A")
    print("│" + f"   All blocked:    {blocked_str}"[:W].ljust(W) + "│")
    print("├" + "─" * W + "┤")

    # Matched sessions
    print("│" + f" MATCHED SESSIONS ({total_matched})".ljust(W) + "│")
    print("│" + " " + "─" * (W-4) + " │")

    for i, v in enumerate(filtered, 1):
        vid = v.get("id", "N/A")
        start = ts_to_short(v.get("startTime"))
        end = ts_to_short(v.get("endTime"))
        dur = ""
        try:
            dur = f"{int((int(v.get('endTime', 0)) - int(v.get('startTime', 0))) / 1000)}s"
        except:
            pass

        ips = ", ".join(str(x) for x in v.get("clientIPs", [])) if v.get("clientIPs") else "N/A"
        country = ", ".join(str(x) for x in v.get("country", [])) if v.get("country") else "N/A"
        ctype = v.get("clientType", "N/A")
        app = v.get("clientApplication", "N/A")
        hits = v.get("hits", 0)
        entry = v.get("entryPage", "N/A")[:50]
        served = ", ".join(str(x) for x in v.get("servedVia", [])) if v.get("servedVia") else "N/A"

        sec = v.get("security_summary", {})
        sec_str = ""
        if isinstance(sec, dict) and sec:
            sec_str = ", ".join(f"{k.split('.')[-1]}:{val}" for k, val in list(sec.items())[:3])

        actions = v.get("actions", [])
        action_count = len(actions)
        first_result = actions[0].get("requestResult", "").split(".")[-1] if actions else "N/A"

        threat_rules = []
        attack_codes = []
        for a in actions:
            for t in a.get("threats", []):
                rule = t.get("securityRule", "").split(".")[-1]
                if rule not in threat_rules:
                    threat_rules.append(rule)
                for code in t.get("attackCodes", []):
                    sc = str(code)
                    if sc not in attack_codes:
                        attack_codes.append(sc)

        print("│" + f" [{i:02d}] {start}  ({dur})".ljust(W) + "│")
        print("│" + f"      ID: {vid}".ljust(W) + "│")
        print("│" + f"      IP: {ips}  |  {country}".ljust(W) + "│")
        print("│" + f"      {ctype} / {app}  |  {fmt_number(hits)} hits".ljust(W) + "│")
        print("│" + f"      Entry: {entry}".ljust(W) + "│")
        print("│" + f"      PoP: {served}".ljust(W) + "│")
        if sec_str:
            print("│" + f"      Security: {sec_str}"[:W].ljust(W) + "│")
        print("│" + f"      Actions: {action_count} requests  |  First result: {first_result}"[:W].ljust(W) + "│")
        if threat_rules:
            print("│" + f"      Rules: {', '.join(threat_rules)}"[:W].ljust(W) + "│")
        if attack_codes:
            print("│" + f"      Attack Codes: {', '.join(attack_codes)}"[:W].ljust(W) + "│")
        if i < len(filtered):
            print("│" + "   " + "·" * (W-6) + "  │")

    print("├" + "─" * W + "┤")

    # Aggregate statistics
    print("│" + " AGGREGATE STATISTICS".ljust(W) + "│")
    print("│" + " " + "─" * (W-4) + " │")

    for counter, title in [
        (country_counter, "By Country"), (type_counter, "By Client Type"),
        (app_counter, "By Application"), (pop_counter, "By PoP"),
    ]:
        if counter:
            print("│" + f"   {title}:".ljust(W) + "│")
            for k, cnt in counter.most_common(10 if title == "By Country" else 20):
                print("│" + f"      {k:<20} {fmt_number(cnt):>6}"[:W].ljust(W) + "│")

    if result_counter:
        print("│" + "   By Request Result:".ljust(W) + "│")
        for r, cnt in result_counter.most_common():
            short = r.split(".")[-1] if "." in r else r
            print("│" + f"      {short:<30} {fmt_number(cnt):>6}"[:W].ljust(W) + "│")

    if rule_counter:
        print("│" + "   Security Rules Triggered:".ljust(W) + "│")
        for r, cnt in rule_counter.most_common():
            short = r.split(".")[-1] if "." in r else r
            print("│" + f"      {short:<30} {fmt_number(cnt):>6}"[:W].ljust(W) + "│")

    if attack_code_counter:
        print("│" + "   Attack Codes:".ljust(W) + "│")
        for code, cnt in attack_code_counter.most_common():
            print("│" + f"      {code:<20} {fmt_number(cnt):>6}"[:W].ljust(W) + "│")

    if path_counter:
        print("│" + "   Top Paths:".ljust(W) + "│")
        for p, cnt in path_counter.most_common(10):
            short = p[:40] if len(p) > 40 else p
            print("│" + f"      {short:<40} {fmt_number(cnt):>4}"[:W].ljust(W) + "│")

    print("├" + "─" * W + "┤")

    # Suggested actions
    print("│" + " ⚡ SUGGESTED ACTIONS".ljust(W) + "│")
    print("│" + " " + "─" * (W-4) + " │")

    suggestions = []
    if all_blocked and total_matched > 0:
        if len(country_counter) == 1:
            suggestions.append(f"All traffic from {list(country_counter.keys())[0]} — consider country-level rule review")
        if len(type_counter) == 1:
            suggestions.append(f"All classified as '{list(type_counter.keys())[0]}' — verify classification accuracy")
        scanner_apps = {"Go HTTP library", "cURL", "python-requests", "Node.js"}
        matched_scanners = set(app_counter.keys()) & scanner_apps
        if matched_scanners:
            suggestions.append(f"Scanner tools detected ({', '.join(matched_scanners)}) — expected for test site")
        git_paths = [p for p in path_counter if ".git" in p.lower()]
        if git_paths:
            suggestions.append(f".git scanning detected ({len(git_paths)} unique paths) — ensure no repo exposure")
        if attack_code_counter:
            codes = list(attack_code_counter.keys())[:5]
            suggestions.append(f"Attack codes triggered: {', '.join(codes)}")
            suggestions.append("Review custom rules if these are false positives")

    if not suggestions:
        suggestions.append("No specific patterns detected — manual review recommended")

    for s in suggestions:
        print("│" + f"   → {s}"[:W].ljust(W) + "│")

    print("│" + "".ljust(W) + "│")
    print("│" + "   To whitelist/exception an IP or path, use:".ljust(W) + "│")
    print("│" + "   imperva-cwaf-policy-management skill".ljust(W) + "│")
    print("└" + "─" * W + "┘")
    print()


# ── Stats Formatters ─────────────────────────────────────────────────────────

def print_stats_json(data):
    print(json.dumps(data, indent=2, ensure_ascii=False))


def print_visits_timeseries_table(data):
    visits = data.get("visits_timeseries", [])
    if not visits:
        print("No visit data returned.")
        return
    print(f"\n{'='*70}")
    print("  VISITS TIMESERIES")
    print(f"{'='*70}")
    for series in visits:
        name = series.get("name", "Unknown")
        print(f"\n  [{name}]")
        print(f"  {'Timestamp':<28} {'Count':>10}")
        print(f"  {'-'*28} {'-'*10}")
        for point in series.get("data", []):
            if isinstance(point, (list, tuple)) and len(point) >= 2:
                print(f"  {ts_to_iso(point[0]):<28} {fmt_number(point[1]):>10}")
    print()


def print_hits_timeseries_table(data):
    hits = data.get("hits_timeseries", [])
    if not hits:
        print("No hits data returned.")
        return
    print(f"\n{'='*70}")
    print("  HITS TIMESERIES")
    print(f"{'='*70}")
    for series in hits:
        name = series.get("name", "Unknown")
        print(f"\n  [{name}]")
        print(f"  {'Timestamp':<28} {'Hits/sec':>10}")
        print(f"  {'-'*28} {'-'*10}")
        for point in series.get("data", []):
            if isinstance(point, (list, tuple)) and len(point) >= 2:
                print(f"  {ts_to_iso(point[0]):<28} {fmt_number(point[1]):>10}")
    print()


def print_bandwidth_timeseries_table(data):
    bw = data.get("bandwidth_timeseries", [])
    if not bw:
        print("No bandwidth data returned.")
        return
    print(f"\n{'='*70}")
    print("  BANDWIDTH TIMESERIES")
    print(f"{'='*70}")
    for series in bw:
        name = series.get("name", "Unknown")
        print(f"\n  [{name}]")
        print(f"  {'Timestamp':<28} {'Bytes':>15} {'Bits/s':>15}")
        print(f"  {'-'*28} {'-'*15} {'-'*15}")
        for point in series.get("data", []):
            if isinstance(point, (list, tuple)) and len(point) >= 2:
                print(f"  {ts_to_iso(point[0]):<28} {fmt_bytes(point[1]):>15} {fmt_number(point[1]):>15}")
    print()


def print_requests_geo_table(data):
    geo = data.get("requests_geo_dist_summary")
    if not geo:
        print("No geo distribution data returned.")
        return
    geo_data = geo.get("data", [])
    print(f"\n{'='*70}")
    print(f"  {geo.get('name', 'Requests by Location').upper()}")
    print(f"{'='*70}")
    print(f"  {'Location':<30} {'Requests':>15}")
    print(f"  {'-'*30} {'-'*15}")
    for item in geo_data:
        if isinstance(item, (list, tuple)) and len(item) >= 2:
            print(f"  {str(item[0]):<30} {fmt_number(item[1]):>15}")
    print()


def print_visits_dist_table(data):
    visits = data.get("visits_dist_summary", [])
    if not visits:
        print("No visits distribution data returned.")
        return
    print(f"\n{'='*70}")
    print("  VISITS DISTRIBUTION SUMMARY")
    print(f"{'='*70}")
    for series in visits:
        name = series.get("name", "Unknown")
        print(f"\n  [{name}]")
        print(f"  {'Category':<30} {'Count':>10}")
        print(f"  {'-'*30} {'-'*10}")
        for item in series.get("data", []):
            if isinstance(item, (list, tuple)) and len(item) >= 2:
                print(f"  {str(item[0]):<30} {fmt_number(item[1]):>10}")
    print()


def print_caching_table(data):
    caching = data.get("caching")
    if not caching:
        print("No caching data returned.")
        return
    print(f"\n{'='*70}")
    print("  CACHING STATISTICS")
    print(f"{'='*70}")
    print(f"  {'Metric':<35} {'Value':>20}")
    print(f"  {'-'*35} {'-'*20}")
    print(f"  {'Saved Requests':<35} {fmt_number(caching.get('saved_requests', 0)):>20}")
    print(f"  {'Total Requests':<35} {fmt_number(caching.get('total_requests', 0)):>20}")
    print(f"  {'Cache Hit Rate':<35} {caching.get('saved_requests', 0) / max(caching.get('total_requests', 1), 1) * 100:>19.1f}%")
    print(f"  {'Saved Bytes':<35} {fmt_bytes(caching.get('saved_bytes', 0)):>20}")
    print(f"  {'Total Bytes':<35} {fmt_bytes(caching.get('total_bytes', 0)):>20}")
    print(f"  {'Byte Hit Rate':<35} {caching.get('saved_bytes', 0) / max(caching.get('total_bytes', 1), 1) * 100:>19.1f}%")
    print()


def print_caching_timeseries_table(data):
    series_list = data.get("caching_timeseries", [])
    if not series_list:
        print("No caching timeseries data returned.")
        return
    print(f"\n{'='*70}")
    print("  CACHING TIMESERIES")
    print(f"{'='*70}")
    for series in series_list:
        name = series.get("name", "Unknown")
        print(f"\n  [{name}]")
        print(f"  {'Timestamp':<28} {'Value':>15}")
        print(f"  {'-'*28} {'-'*15}")
        for point in series.get("data", []):
            if isinstance(point, (list, tuple)) and len(point) >= 2:
                print(f"  {ts_to_iso(point[0]):<28} {fmt_number(point[1]):>15}")
    print()


def print_threats_table(data):
    threats = data.get("threats", [])
    if not threats:
        print("No threat data returned.")
        return
    print(f"\n{'='*90}")
    print("  THREATS SUMMARY")
    print(f"{'='*90}")
    print(f"  {'Threat Type':<40} {'Incidents':>10} {'Status':<15} {'Action':<15}")
    print(f"  {'-'*40} {'-'*10} {'-'*15} {'-'*15}")
    for t in threats:
        name = t.get("name", "Unknown")
        incidents = t.get("incidents", 0)
        status_text = t.get("status_text", t.get("status", "N/A"))
        followup = t.get("followup_text", "N/A")
        print(f"  {name:<40} {fmt_number(incidents):>10} {status_text:<15} {followup:<15}")
    print()


def print_incap_rules_table(data):
    rules = data.get("incap_rules", [])
    if not rules:
        print("No security rules data returned.")
        return
    print(f"\n{'='*90}")
    print("  SECURITY RULES (INCAP_RULES)")
    print(f"{'='*90}")
    print(f"  {'Rule Name':<40} {'Action':<25} {'Incidents':>10}")
    print(f"  {'-'*40} {'-'*25} {'-'*10}")
    for r in rules:
        name = r.get("name", "Unknown")
        action = r.get("action", "N/A")
        incidents = r.get("incidents", 0)
        print(f"  {name:<40} {action:<25} {fmt_number(incidents):>10}")
    print()


def print_incap_rules_timeseries_table(data):
    series_list = data.get("incap_rules_timeseries", [])
    if not series_list:
        print("No security rules timeseries data returned.")
        return
    print(f"\n{'='*70}")
    print("  SECURITY RULES TIMESERIES")
    print(f"{'='*70}")
    for series in series_list:
        name = series.get("name", "Unknown")
        action = series.get("action", "")
        print(f"\n  [{name}] (action: {action})")
        print(f"  {'Timestamp':<28} {'Incidents':>10}")
        print(f"  {'-'*28} {'-'*10}")
        for point in series.get("incidents", series.get("data", [])):
            if isinstance(point, (list, tuple)) and len(point) >= 2:
                print(f"  {ts_to_iso(point[0]):<28} {fmt_number(point[1]):>10}")
    print()


def print_delivery_rules_table(data):
    rules = data.get("delivery_rules", [])
    if not rules:
        print("No delivery rules data returned.")
        return
    print(f"\n{'='*80}")
    print("  DELIVERY RULES")
    print(f"{'='*80}")
    print(f"  {'Rule Name':<40} {'Action':<20} {'Hits':>10}")
    print(f"  {'-'*40} {'-'*20} {'-'*10}")
    for r in rules:
        name = r.get("name", "Unknown")
        action = r.get("action", "N/A")
        hits = r.get("hits", 0)
        print(f"  {name:<40} {action:<20} {fmt_number(hits):>10}")
    print()


def print_delivery_rules_timeseries_table(data):
    series_list = data.get("delivery_rules_timeseries", [])
    if not series_list:
        print("No delivery rules timeseries data returned.")
        return
    print(f"\n{'='*70}")
    print("  DELIVERY RULES TIMESERIES")
    print(f"{'='*70}")
    for series in series_list:
        name = series.get("name", "Unknown")
        action = series.get("action", "")
        print(f"\n  [{name}] (action: {action})")
        print(f"  {'Timestamp':<28} {'Hits':>10}")
        print(f"  {'-'*28} {'-'*10}")
        for point in series.get("hits", series.get("data", [])):
            if isinstance(point, (list, tuple)) and len(point) >= 2:
                print(f"  {ts_to_iso(point[0]):<28} {fmt_number(point[1]):>10}")
    print()


STATS_FORMATTERS = {
    "visits_timeseries": print_visits_timeseries_table,
    "hits_timeseries": print_hits_timeseries_table,
    "bandwidth_timeseries": print_bandwidth_timeseries_table,
    "requests_geo_dist_summary": print_requests_geo_table,
    "visits_dist_summary": print_visits_dist_table,
    "caching": print_caching_table,
    "caching_timeseries": print_caching_timeseries_table,
    "threats": print_threats_table,
    "incap_rules": print_incap_rules_table,
    "incap_rules_timeseries": print_incap_rules_timeseries_table,
    "delivery_rules": print_delivery_rules_table,
    "delivery_rules_timeseries": print_delivery_rules_timeseries_table,
}


# ── Command: stats ───────────────────────────────────────────────────────────

def cmd_stats(args):
    api_id, api_key = get_credentials()
    site_id, caid = get_identifiers(args)

    params = {
        "site_id": site_id,
        "stats": ",".join(args.stats),
    }
    if caid:
        params["account_id"] = caid
    if args.time_range:
        params["time_range"] = args.time_range
    else:
        params["time_range"] = "last_7_days"
    if params["time_range"] == "custom":
        if not args.start or not args.end:
            print("ERROR: --start and --end required when time_range=custom", file=sys.stderr)
            sys.exit(1)
        params["start"] = args.start
        params["end"] = args.end
    if args.granularity:
        params["granularity"] = args.granularity

    data = api_post("/api/stats/v1", params, api_id, api_key)

    res_code = data.get("res") if isinstance(data, dict) else None
    if res_code and res_code != 0:
        res_msg = data.get("res_message", "Unknown error")
        print(f"API Error: res={res_code} — {res_msg}", file=sys.stderr)
        if args.format == "json":
            print_stats_json(data)
        sys.exit(1)

    if args.format == "json":
        print_stats_json(data)
    else:
        for stat_name in args.stats:
            formatter = STATS_FORMATTERS.get(stat_name)
            if formatter:
                formatter(data)
            else:
                print(f"\n--- {stat_name} ---")
                print(json.dumps(data.get(stat_name, "N/A"), indent=2, ensure_ascii=False))


# ── Command: visits ──────────────────────────────────────────────────────────

def cmd_visits(args):
    api_id, api_key = get_credentials()
    site_id, caid = get_identifiers(args)

    # Handle incident_id → visit_id extraction
    visit_id = getattr(args, 'visit_id', None)
    incident_id = getattr(args, 'incident_id', None)
    if incident_id and not visit_id:
        visit_id = parse_incident_id(incident_id)
        if not visit_id:
            print(f"ERROR: Could not parse visit_id from incident_id: {incident_id}", file=sys.stderr)
            sys.exit(1)

    params = {"site_id": site_id}
    if caid:
        params["account_id"] = caid

    if args.time_range:
        params["time_range"] = args.time_range
    else:
        params["time_range"] = "last_7_days"

    if params["time_range"] == "custom":
        if not args.start or not args.end:
            print("ERROR: --start and --end required when time_range=custom", file=sys.stderr)
            sys.exit(1)
        params["start"] = args.start
        params["end"] = args.end

    if args.security:
        params["security"] = args.security
    if args.country:
        params["country"] = args.country
    if args.ip:
        params["ip"] = args.ip
    if visit_id:
        params["visit_id"] = visit_id

    page_size = getattr(args, 'page_size', None)
    if not page_size:
        page_size = "100"
    params["page_size"] = page_size
    if args.page_num:
        params["page_num"] = args.page_num

    if args.list_live_visits is not None:
        params["list_live_visits"] = "true" if args.list_live_visits else "false"

    data = api_post("/api/visits/v1", params, api_id, api_key)

    res_code = data.get("res") if isinstance(data, dict) else None
    if res_code and res_code != 0:
        res_msg = data.get("res_message", "Unknown error")
        print(f"API Error: res={res_code} — {res_msg}", file=sys.stderr)
        if args.format == "json":
            print(json.dumps(data, indent=2, ensure_ascii=False))
        sys.exit(1)

    visits = data.get("visits", [])
    filtered = apply_client_side_filters(visits, args)

    if args.format == "json":
        output = dict(data)
        output["visits"] = filtered
        output["_filter_info"] = {
            "total_fetched": len(visits),
            "total_matched": len(filtered),
        }
        print(json.dumps(output, indent=2, ensure_ascii=False))

    elif args.format == "report":
        generate_analysis_report(visits, filtered, args)

    else:
        if not filtered:
            print("No visits matched the filters.")
            return

        print(f"\n{'='*120}")
        print(f"  VISIT LOGS — {len(filtered)} sessions matched (from {len(visits)} fetched)")
        print(f"{'='*120}")

        for i, v in enumerate(filtered, 1):
            visit_id_v = v.get("id", "N/A")
            start = ts_to_iso(v.get("startTime"))
            end = ts_to_iso(v.get("endTime"))
            client_ips = ", ".join(str(x) for x in v.get("clientIPs", [])) if v.get("clientIPs") else "N/A"
            country = ", ".join(str(x) for x in v.get("country", [])) if v.get("country") else "N/A"
            client_type = v.get("clientType", "N/A")
            client_app = v.get("clientApplication", "N/A")
            user_agent = v.get("userAgent", "N/A")
            os_info = f"{v.get('os', '')} {v.get('osVersion', '')}".strip()
            hits = v.get("hits", 0)
            page_views = v.get("pageViews", 0)
            entry_page = v.get("entryPage", "N/A")
            served_via = ", ".join(str(x) for x in v.get("servedVia", [])) if v.get("servedVia") else "N/A"

            sec_summary = v.get("security_summary", [])
            threats_str = ""
            if sec_summary:
                if isinstance(sec_summary, dict):
                    threats_str = ", ".join(f"{k}: {val}" for k, val in sec_summary.items())
                elif isinstance(sec_summary, list):
                    threats_str = ", ".join(str(x) for x in sec_summary)

            print(f"\n  ── Visit #{i} ──────────────────────────────────────────────────────")
            print(f"  ID:             {visit_id_v}")
            print(f"  Time:           {start} → {end}")
            print(f"  Client IPs:     {client_ips}")
            print(f"  Country:        {country}")
            print(f"  Type:           {client_type}")
            print(f"  Application:    {client_app}")
            print(f"  OS:             {os_info}")
            print(f"  User-Agent:     {user_agent[:80]}")
            print(f"  Hits:           {fmt_number(hits)}  |  Page Views: {fmt_number(page_views)}")
            print(f"  Entry Page:     {entry_page}")
            print(f"  Served Via:     {served_via}")
            if threats_str:
                print(f"  Threats:        {threats_str}")

            actions = v.get("actions", [])
            if actions:
                print(f"  Actions ({len(actions)}):")
                for a in actions[:5]:
                    url = a.get("url", "N/A")[:60]
                    result = a.get("requestResult", "N/A")
                    status = a.get("httpStatus", "N/A")
                    resp_time = a.get("responseTime", "N/A")
                    print(f"    → {url}  [{result}] HTTP {status} ({resp_time}ms)")
                if len(actions) > 5:
                    print(f"    ... and {len(actions) - 5} more actions")
        print()


# ── CLI ──────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        description="Imperva CWAF — Statistics & Visits",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    parser.add_argument("command", choices=["stats", "visits"], help="Operation to perform")
    parser.add_argument("--site-id", help="Site ID (or set SITE_ID env var)")
    parser.add_argument("--caid", help="Account CAID (or set CAID env var)")
    parser.add_argument("--format", choices=["table", "json", "report"], default="table",
                        help="Output format: table, json, or report (analysis). Default: table")

    # Stats-specific
    stats_group = parser.add_argument_group("stats options")
    stats_group.add_argument("--stats", nargs="+", default=["threats"],
                             help=f"Stat types to fetch. Valid: {', '.join(VALID_STATS)}")
    stats_group.add_argument("--time-range", dest="time_range",
                             help=f"Time range. Valid: {', '.join(VALID_TIME_RANGES)}. Default: last_7_days")
    stats_group.add_argument("--start", help="Start timestamp (ms since epoch) for custom range")
    stats_group.add_argument("--end", help="End timestamp (ms since epoch) for custom range")
    stats_group.add_argument("--granularity", help="Time interval in ms between data points (min 300000)")

    # Visits — API-side filters
    visits_group = parser.add_argument_group("visits API filters (sent to API)")
    visits_group.add_argument("--security", help="Filter by security threat type")
    visits_group.add_argument("--country", help="Filter by country code, e.g. TH, BG")
    visits_group.add_argument("--ip", help="Filter by client IP")
    visits_group.add_argument("--visit-id", help="Filter by visit ID(s), comma-separated")
    visits_group.add_argument("--incident-id", help="Filter by incident ID (auto-extracts visit_id)")
    visits_group.add_argument("--page-size", help="Results per page (default 100 for filtering, max 100)")
    visits_group.add_argument("--page-num", help="Page number starting from 0")
    visits_group.add_argument("--list-live-visits", action="store_true", default=None)
    visits_group.add_argument("--no-live-visits", action="store_false", dest="list_live_visits")

    # Visits — client-side filters
    filter_group = parser.add_argument_group("visits client-side filters (applied after fetch)")
    filter_group.add_argument("--filter-type", help="Filter by client type, e.g. 'Hacking Tool', 'Bot'")
    filter_group.add_argument("--filter-app", help="Filter by client application, e.g. 'Go HTTP library', 'cURL'")
    filter_group.add_argument("--filter-path", help="Filter by URL/path pattern, e.g. '.git/config', 'xmlrpc.php'")
    filter_group.add_argument("--filter-result", help="Filter by request result, e.g. 'req_blocked_security'")
    filter_group.add_argument("--filter-attack-code", help="Filter by attack code, e.g. '17296460.0'")
    filter_group.add_argument("--filter-ua", help="Filter by user-agent keyword, e.g. 'Go', 'cURL'")
    filter_group.add_argument("--filter-pop", help="Filter by served via PoP, e.g. 'Dubai', 'Ashburn'")
    filter_group.add_argument("--filter-security-rule", help="Filter by security rule name, e.g. 'customRule'")

    args = parser.parse_args()

    if args.command == "stats" and args.stats:
        invalid = [s for s in args.stats if s not in VALID_STATS]
        if invalid:
            print(f"ERROR: Invalid stat types: {', '.join(invalid)}", file=sys.stderr)
            print(f"Valid types: {', '.join(VALID_STATS)}", file=sys.stderr)
            sys.exit(1)

    if args.command == "stats":
        cmd_stats(args)
    elif args.command == "visits":
        cmd_visits(args)


if __name__ == "__main__":
    main()
