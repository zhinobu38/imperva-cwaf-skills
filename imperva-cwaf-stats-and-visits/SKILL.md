---
name: imperva-cwaf-stats-and-visits
description: Retrieve Imperva Cloud WAF site statistics and visit logs — threats, visits, bandwidth, caching, security rules, delivery rules, and session-level visit details with filtering, analysis report, and table/JSON output.
category: imperva-cwaf
version: 1.2.0
---

# Imperva CWAF — Statistics & Visits

Retrieve site-level statistics and visit session logs from Imperva Cloud WAF. Supports deep filtering (API-side + client-side), incident ID lookup, and analysis reports.

## Credential & Identifier Policy

| Value | Source | ห้าม |
|-------|--------|------|
| `IMPERVA_API_ID` | `bws run --project-id 61c6c700-2d78-4860-b79e-b46200e193e9` | hardcode ใน script/template/SKILL.md |
| `IMPERVA_API_KEY` | `bws run --project-id 61c6c700-2d78-4860-b79e-b46200e193e9` | print ใน log หรือ raw request output |
| `SITE_ID` | User env / memory / `imperva-cwaf-get-site-detail` | hardcode ใน template |
| `CAID` | User env / memory / `imperva-cwaf-get-site-detail` | hardcode ใน template |

## API Endpoints

| Command | Endpoint | Method |
|---------|----------|--------|
| `stats` | `/api/stats/v1` | POST |
| `visits` | `/api/visits/v1` | POST |

**Base URL:** `https://my.imperva.com`

## Operations

### stats — Get Site Statistics

```
SITE_ID=<id> CAID=<caid> bws run --project-id <bw_id> -- \
  python3 scripts/imperva_get_stats.py stats \
    --stats threats incap_rules caching \
    --time-range last_7_days \
    --format table
```

**Parameters:**

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `--site-id` | Yes* | `SITE_ID` env | Site ID |
| `--caid` | No | `CAID` env | Account CAID |
| `--stats` | No | `threats` | Stat types (see table below). Multiple allowed. |
| `--time-range` | No | `last_7_days` | `today`, `last_7_days`, `last_30_days`, `last_90_days`, `month_to_date`, `custom` |
| `--start` | If `custom` | — | Start timestamp (ms since epoch) |
| `--end` | If `custom` | — | End timestamp (ms since epoch) |
| `--granularity` | No | Auto | Time interval in ms (min 300000 = 5 min) |
| `--format` | No | `table` | `table` (human-readable) or `json` (raw) |

**Valid `--stats` values:**

| Stat Type | Description |
|-----------|-------------|
| `visits_timeseries` | Sessions by type (Humans/Bots) over time |
| `hits_timeseries` | Requests by type (Humans/Bots/Blocked) per second |
| `bandwidth_timeseries` | Bandwidth and throughput over time |
| `requests_geo_dist_summary` | Requests by data center location |
| `visits_dist_summary` | Sessions by client app and country |
| `caching` | Total cached requests and bytes |
| `caching_timeseries` | Cached requests/bytes over time (1-day resolution) |
| `threats` | Total threats by type with security rule config |
| `incap_rules` | Security rules with incident counts |
| `incap_rules_timeseries` | Security rules with incident time series |
| `delivery_rules` | Delivery rules with hit counts |
| `delivery_rules_timeseries` | Delivery rules with hit time series |

**Granularity defaults (auto):**
- < 24 hours → 7200000ms (2 hours)
- 24 hours – 30 days → 86400000ms (1 day)
- > 30 days → 259200000ms (3 days)

### visits — Get Visit Session Logs

```
SITE_ID=<id> CAID=<caid> bws run --project-id <bw_id> -- \
  python3 scripts/imperva_get_stats.py visits \
    --security api.threats.sql_injection \
    --country TH \
    --page-size 20 \
    --format table
```

**Parameters — API-side filters (sent directly to API):**

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `--site-id` | Yes* | `SITE_ID` env | Site ID |
| `--caid` | No | `CAID` env | Account CAID |
| `--time-range` | No | `last_7_days` | Same as stats |
| `--start` | If `custom` | — | Start timestamp (ms) |
| `--end` | If `custom` | — | End timestamp (ms) |
| `--security` | No | — | Filter by threat type, e.g. `api.threats.sql_injection` |
| `--country` | No | — | Filter by country code, e.g. `TH`, `SE` |
| `--ip` | No | — | Filter by client IP |
| `--visit-id` | No | — | Filter by visit ID(s), comma-separated |
| `--incident-id` | No | — | Filter by incident ID. Format: `<visit_id>-<number>`. Auto-extracts visit_id. |
| `--page-size` | No | 100 | Results per page (max 100). Default 100 for better client-side filtering. |
| `--page-num` | No | 0 | Page number (0-based) |
| `--list-live-visits` | No | true | Include incomplete/live visits |
| `--no-live-visits` | No | — | Exclude incomplete/live visits |

**Incident ID format:** Imperva incident IDs follow the pattern `<visit_id>-<incident_number>` (e.g. `526000340320036642-169334527402838191`). Use `--incident-id` to look up a specific incident — the script auto-extracts the visit_id portion.

**Parameters — Client-side filters (applied after API fetch):**

These filters are applied in Python after fetching visits from the API. Combine with `--page-size 100` for broad queries.

| Parameter | Description | Example |
|-----------|-------------|---------|
| `--filter-type` | Filter by `clientType` (substring match) | `Hacking Tool`, `Bot` |
| `--filter-app` | Filter by `clientApplication` (substring match) | `Go HTTP library`, `cURL` |
| `--filter-path` | Filter by URL path in `actions[].url` or `entryPage` (substring) | `.git/config`, `xmlrpc.php` |
| `--filter-result` | Filter by `actions[].requestResult` (substring) | `req_blocked_security` |
| `--filter-attack-code` | Filter by attack code in `actions[].threats[].attackCodes` | `17296460.0`, `17489321.0` |
| `--filter-ua` | Filter by `userAgent` keyword (substring, case-insensitive) | `Go`, `cURL`, `python` |
| `--filter-pop` | Filter by `servedVia` PoP location (substring) | `Dubai`, `Ashburn` |
| `--filter-security-rule` | Filter by security rule name in `actions[].threats[].securityRule` or `security_summary` (substring) | `customRule`, `illegal_resource_access` |

**Client-side filter workflow:**
1. API is called with API-side filters (country, ip, time, etc.)
2. All returned visits are scanned against client-side filters
3. Only visits matching ALL specified client-side filters are shown
4. Each visit must have at least one action matching path/result/ua/attack-code filters

## Response Structure

### /api/stats/v1

```json
{
  "res": 0,
  "res_message": "OK",
  "debug_info": [],
  "visits_timeseries": [...],
  "threats": [...],
  "caching": { "saved_requests": ..., "total_requests": ..., "saved_bytes": ..., "total_bytes": ... },
  "incap_rules": [...],
  ...
}
```

Each stat type appears as a top-level key when requested.

### /api/visits/v1

```json
{
  "res": 0,
  "res_message": "OK",
  "debug_info": [],
  "visits": [
    {
      "id": "526000340320036642",
      "siteId": 852056322,
      "startTime": 1781545009419,
      "endTime": 1781545608000,
      "clientIPs": ["85.11.167.19"],
      "country": ["Bulgaria"],
      "countryCode": ["BG"],
      "clientType": "Hacking Tool",
      "clientApplication": "Go HTTP library",
      "clientApplicationId": 589,
      "httpVersion": "1.1",
      "userAgent": "Mozilla/5.0 ...",
      "supportsCookies": false,
      "supportsJavaScript": false,
      "hits": 1,
      "pageViews": 0,
      "entryPage": "POST testagent.thtechs.com/",
      "entryReferer": "https://testagent.thtechs.com",
      "servedVia": ["Dubai, UAE"],
      "securitySummary": { "api.threats.customRule": 1 },
      "actions": [
        {
          "url": "testagent.thtechs.com/",
          "requestResult": "api.request_result.req_blocked_security",
          "isSecured": true,
          "responseTime": 2,
          "incidentId": "526000340320036642-169334527402838191",
          "threats": [
            {
              "securityRule": "api.threats.customRule",
              "alertLocation": "api.alert_location.alert_location_path",
              "threatPattern": "testagent.thtechs.com/",
              "attackCodes": ["17296460.0"],
              "securityRuleAction": "api.rule_action_type.rule_action_block"
            }
          ]
        }
      ]
    }
  ]
}
```

## Output Formats

### `--format table` (default)

**IMPORTANT:** Always use rich visual formatting — box-drawing characters (╔═╗║╚╝╠╣), emoji indicators (🛡️🤖🌍📈💾🔴🟢⚡✅), visual bar charts (█░), and structured sections with headers. Plain text tables are NOT acceptable for user-facing output.

Each stat type gets its own formatted section. Visit logs show one card per session with all fields.

### `--format json`

Raw API JSON response. Suitable for agent/programmatic consumption, piping to `jq`, or further processing. When client-side filters are applied, a `_filter_info` key is added with `total_fetched` and `total_matched` counts.

### `--format report`

Analysis report for visits. Shows:
- Filter conditions applied
- Results summary (total fetched, matched, match rate, all-blocked status)
- Each matched session with: ID, time, IP, country, client type/app, entry page, PoP, action count, first result, triggered rules, attack codes
- Aggregate statistics: by country, client type, application, request result, security rules, attack codes, PoP, top paths
- Suggested actions based on patterns detected (scanner tools, .git probing, country concentration, etc.)
- Pointer to `imperva-cwaf-policy-management` skill for whitelist/exception

Use this format when investigating "who got blocked and why" or "is this IP/rule causing false positives".

## Known Reference Data

### Known Attack Codes

Attack codes are found in `actions[].threats[].attackCodes[]`. These identify the specific custom rule or security rule that triggered.

| Attack Code | Seen In | Likely Rule |
|-------------|---------|-------------|
| `17296460.0` | Most blocked sessions | customRule (high-frequency) |
| `17489321.0` | Most blocked sessions | customRule (high-frequency) |
| `901608.0` | UK/US sessions | customRule |
| `309140.0` | .git/config probes | illegal_resource_access |
| `306024.0` | .git/config probes | illegal_resource_access |
| `904780.0` | .git/config probes | illegal_resource_access |
| `-72500534.2` | Bot POST sessions | customRule (negative code) |
| `17579496.0` | Login page probes | customRule |
| `903390.0` | Rare | customRule |

### Known Request Results

Request results are found in `actions[].requestResult`.

| Result | Meaning |
|--------|---------|
| `req_blocked_security` | Blocked by security rule (customRule, illegal_resource_access, etc.) |
| `req_blocked_cookieless_session` | Blocked — client doesn't support cookies (bot/scanner) |
| `req_bad_parse_error` | Blocked — malformed request |
| `req_challenge_javascript` | Challenged with JavaScript (CAPTCHA) |
| `req_challenge_captcha` | Challenged with CAPTCHA |

### Known Client Types

| Type | Description |
|------|-------------|
| `Hacking Tool` | Automated scanner (Go HTTP library, cURL, etc.) |
| `Bot` | Bot traffic (news aggregators, search engines, etc.) |
| `Browser Impersonator` | Pretends to be a browser but isn't |
| `Unclassified` | Could not be classified |

### Known Client Applications

| Application | Typical Behavior |
|-------------|-----------------|
| `Go HTTP library` | Scanner — brute-force path probing |
| `cURL` | Scanner — targeted requests |
| `Node.js` | Scanner — automated scripts |
| `Bot` | News aggregators, search engines |
| `Browser Impersonator` | Pretends to be Chrome/Firefox |
| `ClaudeBot` | Anthropic AI crawler |
| `Firefox (NC)` | Firefox non-crawler |

## Error Handling

| Code | Meaning | Action |
|------|---------|--------|
| 0 | Success | — |
| 1 | Unexpected error | Check params |
| 2 | Invalid input | Check parameter values |
| 15 | WAF IP block | Auto-retry with backoff (5s, 15s, 30s, 60s) |
| 13001 | Invalid time range | Check time_range value |
| 13002 | Invalid granularity | Check granularity value |
| 3015 | Internal error | Retry |
| 9415 | Wrong project | Verify bws project ID |

## Pitfalls

- **WAF Error 15**: Imperva intermittently blocks cloud/AWS IPs. Script auto-retries with exponential backoff. Don't assume script is broken on first 15 error.
- **Inline Python through bws run**: Complex Python must be in a script file, not inline `python3 -c "..."`. This skill uses a script file.
- **SITE_ID required**: Both commands require SITE_ID. CAID is optional but recommended.
- **Time range `custom`**: Requires both `--start` and `--end` in milliseconds since epoch.
- **Granularity minimum**: 300000ms (5 minutes). Values below this will be rejected.
- **Multiple stats**: Can request multiple `--stats` values in one call. Each appears as a top-level key in the response.
- **Client-side filters**: When using `--filter-path`, `--filter-result`, `--filter-ua`, etc., increase `--page-size` to 100 to fetch enough data for post-filtering. Filters are applied per-visit: a visit matches if ANY of its actions match the filter criteria.
- **Rich output required**: User expects visually formatted output with box-drawing, emoji, and bar charts. Never output plain text tables or raw data without formatting when in table mode.
- **bws run quoting**: When passing arguments with spaces (e.g. `--filter-type "Hacking Tool"`) through `bws run`, the outer shell may split them. Use the wrapper script (`scripts/imperva-visits.sh`) or write args to a temp file. Single-word values (e.g. `HackingTool`) work without quoting.

## Examples

```bash
# ── Stats ──

# Threats summary for last 7 days (table)
SITE_ID=852056322 CAID=2429928 bws run --project-id <id> -- \
  python3 scripts/imperva_get_stats.py stats --stats threats

# Multiple stats as JSON
SITE_ID=852056322 CAID=2429928 bws run --project-id <id> -- \
  python3 scripts/imperva_get_stats.py stats \
    --stats threats incap_rules caching visits_timeseries \
    --format json

# Custom time range
SITE_ID=852056322 CAID=2429928 bws run --project-id <id> -- \
  python3 scripts/imperva_get_stats.py stats \
    --stats bandwidth_timeseries \
    --time-range custom \
    --start 1718496000000 --end 1719100800000

# ── Visits — API-side filters ──

# Visits from Thailand with SQL injection attempts
SITE_ID=852056322 CAID=2429928 bws run --project-id <id> -- \
  python3 scripts/imperva_get_stats.py visits \
    --country TH --security api.threats.sql_injection

# Specific visit by ID
SITE_ID=852056322 CAID=2429928 bws run --project-id <id> -- \
  python3 scripts/imperva_get_stats.py visits \
    --visit-id 526000340320036642 \
    --format json

# Lookup by incident ID (auto-extracts visit_id)
SITE_ID=852056322 CAID=2429928 bws run --project-id <id> -- \
  python3 scripts/imperva_get_stats.py visits \
    --incident-id 526000340320036642-169334527402838191 \
    --format json

# ── Visits — Client-side filters ──

# Find all Go HTTP scanner sessions
SITE_ID=852056322 CAID=2429928 bws run --project-id <id> -- \
  python3 scripts/imperva_get_stats.py visits \
    --filter-app "Go HTTP library" \
    --filter-type "Hacking Tool" \
    --page-size 100 \
    --time-range last_7_days

# Find .git/config probes
SITE_ID=852056322 CAID=2429928 bws run --project-id <id> -- \
  python3 scripts/imperva_get_stats.py visits \
    --filter-path ".git/config" \
    --page-size 100 \
    --time-range last_7_days

# Find blocked security sessions from Bulgaria
SITE_ID=852056322 CAID=2429928 bws run --project-id <id> -- \
  python3 scripts/imperva_get_stats.py visits \
    --country BG \
    --filter-result "req_blocked_security" \
    --page-size 100

# Find sessions served via Dubai PoP
SITE_ID=852056322 CAID=2429928 bws run --project-id <id> -- \
  python3 scripts/imperva_get_stats.py visits \
    --filter-pop "Dubai" \
    --page-size 100 \
    --time-range last_7_days

# ── Visits — Analysis reports ──

# Analysis report: who got blocked and why (.git probes)
SITE_ID=852056322 CAID=2429928 bws run --project-id <id> -- \
  python3 scripts/imperva_get_stats.py visits \
    --filter-path ".git" \
    --page-size 100 \
    --format report

# Analysis report: specific attack code investigation
SITE_ID=852056322 CAID=2429928 bws run --project-id <id> -- \
  python3 scripts/imperva_get_stats.py visits \
    --filter-attack-code "17489321.0" \
    --page-size 100 \
    --format report

# Analysis report: country + client type + path combination
SITE_ID=852056322 CAID=2429928 bws run --project-id <id> -- \
  python3 scripts/imperva_get_stats.py visits \
    --country BG \
    --filter-type HackingTool \
    --filter-path .git \
    --page-size 100 \
    --format report

# ── Using wrapper script (for args with spaces) ──

# The wrapper script handles quoting properly through bws run
SITE_ID=852056322 CAID=2429928 bws run --project-id <id> -- \
  bash scripts/imperva-visits.sh \
    --filter-type "Hacking Tool" \
    --filter-app "Go HTTP library" \
    --page-size 100 \
    --format report
```

## Related Skills

- `imperva-cwaf-get-site-detail` — List/search sites to find SITE_ID
- `imperva-cwaf-api-manual` — Full API specification reference
- `imperva-cwaf-policy-management` — Manage WAF rules, ACL, whitelist policies and exceptions
- `imperva-cwaf-status-check` — Check Imperva service status
