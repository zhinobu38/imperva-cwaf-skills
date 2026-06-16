---
name: imperva-cwaf-troubleshoot
description: Troubleshoot website performance and availability issues through Imperva Cloud WAF — check performance statistics (latency, origin response time, errors), inspect site configuration, and diagnose delivery problems
category: imperva-cwaf
version: 1.0.0
---

# Imperva CWAF Troubleshoot

Diagnose website performance and availability issues through Imperva Cloud WAF. Combines performance statistics, site configuration checks, and error analysis in a unified troubleshooting workflow.

## Shared References

| Reference | Description |
|-----------|-------------|
| `../references/skill-dev-standard.md` | Dev standard |
| `../references/credential-and-identifier-policy.md` | Credential rules |
| `../references/shell-template-pattern.md` | Shell template patterns |
| `../imperva-cwaf-api-manual/api-spec/performance-statistics-api.json` | Performance Statistics API spec |

## Credential & Identifier Policy (MANDATORY)

| Value | Source | ห้าม |
|-------|--------|------|
| `IMPERVA_API_ID` | `bws run --project-id 61c6c700-2d78-4860-b79e-b46200e193e9` | hardcode ใน script/template/SKILL.md |
| `IMPERVA_API_KEY` | `bws run --project-id 61c6c700-2d78-4860-b79e-b46200e193e9` | print ใน log หรือ raw request output |
| `SITE_ID` | User env / memory / `imperva-cwaf-get-site-detail` | hardcode ใน template |
| `CAID` | User env / memory / `imperva-cwaf-get-site-detail` | hardcode ใน template |

## API Endpoints

| Command | Endpoint | Method | Base URL |
|---------|----------|--------|----------|
| `performance` | `/v3/performance/statistics` | GET | `https://api.imperva.com/appdlv-dashboards-ui` |

## Operations

### performance — Get Performance Statistics

Retrieves application performance statistics for the last reliable minute (the minute that ended 5 minutes ago). Supports three metric types:

- **popLatency**: Total time (ms) from Imperva proxy selecting an origin server to full response sent back. Excludes redirects.
- **originResponseTime**: Time (ms) from Imperva proxy sending request to origin until response headers received. Excludes redirects.
- **errorResponseTypes**: Count of requests by error type (e.g., REQ_BAD_TIMEOUT, REQ_SSL_NOT_SUPPORTED).

```bash
# All metrics for all sites in account
CAID=<caid> bws run --project-id <bw_id> -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-troubleshoot/scripts/get-performance-stats.sh

# Specific site, all metrics
SITE_ID=<id> CAID=<caid> bws run --project-id <bw_id> -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-troubleshoot/scripts/get-performance-stats.sh

# Specific site, specific metrics
SITE_ID=<id> CAID=<caid> METRICS=popLatency,errorResponseTypes bws run --project-id <bw_id> -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-troubleshoot/scripts/get-performance-stats.sh

# JSON output (for scripting / jq)
SITE_ID=<id> CAID=<caid> OUTPUT_FORMAT=json bws run --project-id <bw_id> -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-troubleshoot/scripts/get-performance-stats.sh
```

**Parameters:**

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `SITE_ID` | No* | — | Site ID to filter. If omitted, returns all sites in account. |
| `CAID` | No | — | Account CAID. If omitted, uses API credential's account. |
| `METRICS` | No | all | Comma-separated: `popLatency`, `originResponseTime`, `errorResponseTypes` |
| `POP` | No | — | Filter by PoP name (client-side, case-insensitive substring match). Filters both popLatency PoPs and originResponseTime originPoP. |
| `OUTPUT_FORMAT` | No | `table` | `table` (rich visual) or `json` (raw) |

*When SITE_ID is omitted, statistics for all sites in the account are returned.

**Response Structure:**

```json
{
  "data": [
    {
      "timestamp": 1730122740000,
      "accountId": 11111,
      "sitesStatistics": [
        {
          "siteId": 222,
          "siteName": "example.website.com",
          "statistics": {
            "popLatency": [
              {
                "region": "us-east",
                "valuePerRegion": 123,
                "pops": [{ "pop": "atl", "valuePerPop": 123 }]
              }
            ],
            "originResponseTime": [
              {
                "server": "1.1.1.1",
                "dataCenterName": "My DC",
                "originPop": "atl",
                "avgResponseTime": 234
              }
            ],
            "errorResponseTypes": {
              "REQ_BAD_TIMEOUT": 3,
              "REQ_SSL_NOT_SUPPORTED": 1
            }
          }
        }
      ]
    }
  ]
}
```

**popLatency — Regional/PoP Latency Breakdown:**

| Field | Description |
|-------|-------------|
| `region` | Region name (e.g., `us-east`, `apac`) |
| `valuePerRegion` | Average latency (ms) across all PoPs in the region |
| `pops[].pop` | 3-digit PoP code (e.g., `atl`, `mel`) |
| `pops[].valuePerPop` | Average latency (ms) for that specific PoP |

**originResponseTime — Per-Origin Response Time:**

| Field | Description |
|-------|-------------|
| `server` | Origin server IP or hostname |
| `dataCenterName` | Data center name as defined in Imperva |
| `originPop` | Imperva PoP used to route traffic to this origin |
| `avgResponseTime` | Average response time in milliseconds |

**errorResponseTypes — Error Counts:**

| Error Type | Description |
|------------|-------------|
| `REQ_BAD_TIMEOUT` | Request timed out |
| `REQ_SSL_NOT_SUPPORTED` | SSL not supported by origin |
| `REQ_IPV6_NOT_SUPPORTED` | IPv6 not supported |
| `REQ_BAD_PARSE_ERROR` | Malformed request |

## Output Formats

### `--format table` (default)

Rich visual output with box-drawing characters, emoji indicators, and structured sections:

- Summary header with timestamp and account ID
- Per-site section with site name and ID
- popLatency: table with region/PoP breakdown and latency values
- originResponseTime: table with per-origin response times
- errorResponseTypes: table with error type counts

### `--format json`

Raw API JSON response. Suitable for scripting, piping to `jq`, or further processing.

## Error Handling

| Code | Meaning | Action |
|------|---------|--------|
| 200 | Success | — |
| 400 | Bad Request | Check parameter values |
| 429 | Rate limit exceeded | Wait and retry |
| 500 | Internal server error | Retry |
| 15 (HTTP 403) | WAF intermittent block | Retry with exponential backoff (5s, 15s, 30s, 60s) |

## Troubleshooting Workflow

### 1. Check Performance Statistics

```bash
# Quick overview — all sites, all metrics
CAID=2429928 bws run --project-id 61c6c700-2d78-4860-b79e-b46200e193e9 -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-troubleshoot/scripts/get-performance-stats.sh
```

### 2. Drill Down to Specific Site

```bash
# Focus on a specific site with high latency
SITE_ID=852056322 CAID=2429928 bws run --project-id 61c6c700-2d78-4860-b79e-b46200e193e9 -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-troubleshoot/scripts/get-performance-stats.sh
```

### 3. Check Specific Metrics

```bash
# Only latency and errors (skip origin response time)
SITE_ID=852056322 CAID=2429928 METRICS=popLatency,errorResponseTypes bws run --project-id 61c6c700-2d78-4860-b79e-b46200e193e9 -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-troubleshoot/scripts/get-performance-stats.sh
```

### 4. Analyze Errors

```bash
# Get only error response types
SITE_ID=852056322 CAID=2429928 METRICS=errorResponseTypes bws run --project-id <bw_id> -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-troubleshoot/scripts/get-performance-stats.sh
```

### 5. Filter by PoP

```bash
# Show only stats for a specific PoP (e.g., "atl" in Atlanta)
SITE_ID=852056322 CAID=2429928 POP=atl bws run --project-id <bw_id> -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-troubleshoot/scripts/get-performance-stats.sh

# Combine POP filter with specific metrics
SITE_ID=852056322 CAID=2429928 POP=atl METRICS=popLatency bws run --project-id <bw_id> -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-troubleshoot/scripts/get-performance-stats.sh

# Partial match works (case-insensitive)
SITE_ID=852056322 CAID=2429928 POP=at bws run --project-id <bw_id> -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-troubleshoot/scripts/get-performance-stats.sh
```

## Common PoP Codes

| PoP Code | Location | Notes |
|----------|----------|-------|
| `DMK` | Thailand (Bangkok) | ใช้บ่อยสำหรับ traffic ในไทย |
| `SIN` | Singapore | ใช้บ่อยสำหรับ traffic ในสิงคโปร์/เอเชียตะวันออกเฉียงใต้ |

## Pitfalls

- **Data freshness**: Statistics reflect the "last reliable minute" — the minute that ended 5 minutes ago. This is NOT real-time data.
- **Redirect requests excluded**: Both popLatency and originResponseTime exclude redirect requests from their averages.
- **siteIds limit**: Maximum 10 site IDs per request.
- **WAF intermittent block (errorCode 15)**: Imperva's WAF may intermittently block API requests from cloud/AWS IPs. Script auto-retries with exponential backoff.
- **Rich output required**: User expects visually formatted output with box-drawing, emoji, and structured sections. Never output plain text tables.
- **POP filter is client-side**: The `POP` env var filters results after the API returns them. It filters both `popLatency[].pops[].pop` and `originResponseTime[].originPop` fields using case-insensitive substring match. If the PoP doesn't exist in the data, arrays will be empty.

## Related Skills

- `imperva-cwaf-get-site-detail`: List and search sites
- `imperva-cwaf-stats-and-visits`: Get site statistics and visit logs
- `imperva-cwaf-status-check`: Check Imperva service status
- `imperva-cwaf-load-balancing`: Check origin server and load balancing config
- `imperva-cwaf-cache`: Check cache configuration and performance
- `imperva-cwaf-ssl-management`: Check SSL/TLS configuration
