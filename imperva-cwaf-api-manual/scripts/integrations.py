#!/usr/bin/env python3
"""
Imperva Integrations API utility script.

Usage:
  python3 integrations.py clapps [--type TYPE] [--name NAME] [--limit N]
  python3 integrations.py geo [--country CODE] [--continent CODE] [--limit N]
  python3 integrations.py texts [--key KEY] [--limit N]
  python3 integrations.py ips [--format FORMAT]

Options:
  --type TYPE       Filter clientApps by type (e.g. Browser, SearchBot, HackingTool)
  --name NAME       Filter clientApps by name (substring match, case-insensitive)
  --country CODE    Filter geo by country code (e.g. TH, US)
  --continent CODE  Filter geo by continent code (e.g. AS, EU)
  --key KEY         Filter texts by message key (substring match)
  --limit N         Max results to display (default: 20, 0=all)
  --format FORMAT   IP ranges format: json|apache|nginx|iptables|text (default: json)
"""

import urllib.request
import urllib.parse
import json
import os
import sys
import argparse


def get_credentials():
    api_id = os.environ.get("IMPERVA_API_ID", "")
    api_key = os.environ.get("IMPERVA_API_KEY", "")
    if not api_id or not api_key:
        print("ERROR: IMPERVA_API_ID or IMPERVA_API_KEY not set", file=sys.stderr)
        sys.exit(1)
    return api_id, api_key


def api_post(path, api_id, api_key):
    url = f"https://my.imperva.com/api/integration/v1/{path}"
    req = urllib.request.Request(url, method="POST")
    req.add_header("Accept", "application/json")
    req.add_header("x-API-Id", api_id)
    req.add_header("x-API-Key", api_key)
    with urllib.request.urlopen(req, timeout=30) as resp:
        return json.loads(resp.read())


def api_get(path, api_id, api_key, params=None):
    url = f"https://my.imperva.com/api/integration/v1/{path}"
    if params:
        url += "?" + urllib.parse.urlencode(params)
    req = urllib.request.Request(url)
    req.add_header("Accept", "application/json")
    req.add_header("x-API-Id", api_id)
    req.add_header("x-API-Key", api_key)
    with urllib.request.urlopen(req, timeout=30) as resp:
        return resp.read().decode()


def show_items(title, items, limit, filter_fn=None):
    if filter_fn:
        items = {k: v for k, v in items.items() if filter_fn(k, v)}
    total = len(items)
    display = list(items.items())[:limit] if limit > 0 else list(items.items())
    print(f"=== {title} ({len(display)} of {total}) ===")
    for k, v in display:
        print(f"  {k}: {v}")
    if limit > 0 and total > limit:
        print(f"  ... and {total - limit} more (use --limit 0 for all)")
    print()


def cmd_clapps(args, api_id, api_key):
    data = api_post("clapps", api_id, api_key)
    if data.get("res") != 0:
        print(f"ERROR: res={data.get('res')} res_message={data.get('res_message')}")
        sys.exit(1)

    apps = data.get("clientApps", {})
    types = data.get("clientAppTypes", {})

    # Build reverse lookup: type_name -> list of app ids
    type_to_ids = {}
    for aid, tname in types.items():
        type_to_ids.setdefault(tname, []).append(aid)

    # Filter by type
    if args.type:
        target_ids = set(type_to_ids.get(args.type, []))
        apps = {k: v for k, v in apps.items() if k in target_ids}
        types = {k: v for k, v in types.items() if k in target_ids}

    # Filter by name
    if args.name:
        name_lower = args.name.lower()
        apps = {k: v for k, v in apps.items() if name_lower in v.lower()}
        types = {k: v for k, v in types.items() if k in apps}

    show_items("clientApps", apps, args.limit)

    # Show type summary if filtered by type
    if args.type:
        print(f"Type '{args.type}' includes {len(apps)} client app(s)")
    else:
        # Show type distribution
        print("=== clientAppTypes summary ===")
        for tname, ids in sorted(type_to_ids.items()):
            print(f"  {tname}: {len(ids)} apps")
    print()


def cmd_geo(args, api_id, api_key):
    data = api_post("geo", api_id, api_key)
    if data.get("res") != 0:
        print(f"ERROR: res={data.get('res')} res_message={data.get('res_message')}")
        sys.exit(1)

    countries = data.get("countriesCodes", {})
    continents = data.get("continentsCodes", {})

    if args.country:
        countries = {k: v for k, v in countries.items() if k == args.country.upper() or args.country.lower() in v.lower()}

    if args.continent:
        continents = {k: v for k, v in continents.items() if k == args.continent.upper() or args.continent.lower() in v.lower()}

    show_items("countriesCodes", countries, args.limit)
    show_items("continentsCodes", continents, args.limit)


def cmd_texts(args, api_id, api_key):
    data = api_post("texts", api_id, api_key)
    if data.get("res") != 0:
        print(f"ERROR: res={data.get('res')} res_message={data.get('res_message')}")
        sys.exit(1)

    texts = data.get("texts", {})

    if args.key:
        key_lower = args.key.lower()
        texts = {k: v for k, v in texts.items() if key_lower in k.lower()}

    show_items("texts", texts, args.limit)


def cmd_ips(args, api_id, api_key):
    fmt = args.format or "json"
    raw = api_get("ips", api_id, api_key, params={"resp_format": fmt})

    if fmt == "json":
        data = json.loads(raw)
        if data.get("res") != 0:
            print(f"ERROR: res={data.get('res')} res_message={data.get('res_message')}")
            sys.exit(1)
        ip_ranges = data.get("ipRanges", [])
        ipv6_ranges = data.get("ipv6Ranges", [])
        print(f"=== IPv4 Ranges ({len(ip_ranges)}) ===")
        for ip in ip_ranges:
            print(f"  {ip}")
        print(f"\n=== IPv6 Ranges ({len(ipv6_ranges)}) ===")
        for ip in ipv6_ranges:
            print(f"  {ip}")
    else:
        print(raw)


def main():
    parser = argparse.ArgumentParser(description="Imperva Integrations API utility")
    sub = parser.add_subparsers(dest="command")

    # clapps
    p_clapps = sub.add_parser("clapps", help="List client applications")
    p_clapps.add_argument("--type", help="Filter by type (Browser, SearchBot, HackingTool, etc.)")
    p_clapps.add_argument("--name", help="Filter by name (substring)")
    p_clapps.add_argument("--limit", type=int, default=20, help="Max results (0=all)")

    # geo
    p_geo = sub.add_parser("geo", help="List country/continent codes")
    p_geo.add_argument("--country", help="Filter by country code or name")
    p_geo.add_argument("--continent", help="Filter by continent code or name")
    p_geo.add_argument("--limit", type=int, default=20, help="Max results (0=all)")

    # texts
    p_texts = sub.add_parser("texts", help="List API text messages")
    p_texts.add_argument("--key", help="Filter by message key (substring)")
    p_texts.add_argument("--limit", type=int, default=20, help="Max results (0=all)")

    # ips
    p_ips = sub.add_parser("ips", help="List Imperva IP ranges")
    p_ips.add_argument("--format", choices=["json", "apache", "nginx", "iptables", "text"], default="json")

    args = parser.parse_args()
    if not args.command:
        parser.print_help()
        sys.exit(1)

    api_id, api_key = get_credentials()

    if args.command == "clapps":
        cmd_clapps(args, api_id, api_key)
    elif args.command == "geo":
        cmd_geo(args, api_id, api_key)
    elif args.command == "texts":
        cmd_texts(args, api_id, api_key)
    elif args.command == "ips":
        cmd_ips(args, api_id, api_key)


if __name__ == "__main__":
    main()
