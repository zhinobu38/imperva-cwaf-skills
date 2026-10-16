#!/bin/bash
# Imperva CWAF — Get Performance Statistics
# Retrieves application performance statistics from Imperva Cloud WAF.
#
# Credential source: Bitwarden (bws run) — DO NOT hardcode
#   IMPERVA_API_ID, IMPERVA_API_KEY injected by bws run
#
# Identifier source: User env vars — DO NOT hardcode in template
#   SITE_ID, CAID must be set by user before calling
#
# Usage:
#   SITE_ID=<id> CAID=<caid> bws run -- bash get-performance-stats.sh
#   CAID=<caid> bws run -- bash get-performance-stats.sh
#
# Environment variables:
#   SITE_ID — Site ID to filter (optional, returns all sites if omitted)
#   CAID — Account CAID (optional, uses API credential's account if omitted)
#   METRICS — Comma-separated metric types: popLatency, originResponseTime, errorResponseTypes (default: all)
#   POP — Filter by PoP name (client-side, case-insensitive substring match on PoP code)
#   OUTPUT_FORMAT — table (default, rich visual) | json (raw JSON)

set -euo pipefail

SITE_ID="${SITE_ID:-}"
CAID="${CAID:-}"
METRICS="${METRICS:-}"
POP="${POP:-}"
OUTPUT_FORMAT="${OUTPUT_FORMAT:-table}"

API_ID="${IMPERVA_API_ID}"
API_KEY="${IMPERVA_API_KEY}"

if [[ -z "$API_ID" || -z "$API_KEY" ]]; then
  echo "Error: IMPERVA_API_ID and IMPERVA_API_KEY must be set (injected by bws run)"
  exit 1
fi

# Build query parameters
PARAMS=""
if [[ -n "$CAID" ]]; then
  PARAMS="caid=${CAID}"
fi
if [[ -n "$SITE_ID" ]]; then
  if [[ -n "$PARAMS" ]]; then
    PARAMS="${PARAMS}&"
  fi
  PARAMS="${PARAMS}siteIds=${SITE_ID}"
fi
if [[ -n "$METRICS" ]]; then
  if [[ -n "$PARAMS" ]]; then
    PARAMS="${PARAMS}&"
  fi
  PARAMS="${PARAMS}metrics=${METRICS}"
fi

BASE_URL="https://api.imperva.com/appdlv-dashboards-ui/v3/performance/statistics"

# Build full URL
URL="${BASE_URL}"
if [[ -n "$PARAMS" ]]; then
  URL="${URL}?${PARAMS}"
fi

# Make API call with retry logic for WAF blocks (error 15)
MAX_RETRIES=4
RETRY_DELAYS=(5 15 30 60)
ATTEMPT=0
RESPONSE=""

while [[ $ATTEMPT -lt $MAX_RETRIES ]]; do
  HTTP_CODE=$(curl -s -o /tmp/perf_stats_resp.txt -w "%{http_code}" \
    -H "Accept: application/json" \
    -H "x-API-Id: ${API_ID}" \
    -H "x-API-Key: ${API_KEY}" \
    "${URL}")

  RESPONSE=$(cat /tmp/perf_stats_resp.txt)

  if [[ "$HTTP_CODE" == "200" ]]; then
    break
  elif [[ "$HTTP_CODE" == "403" ]]; then
    # Check if it's a WAF block (error 15)
    ERROR_CODE=$(echo "$RESPONSE" | jq -r '.errors[0].status // empty' 2>/dev/null || echo "")
    if [[ "$ERROR_CODE" == "15" ]]; then
      ATTEMPT=$((ATTEMPT + 1))
      if [[ $ATTEMPT -lt $MAX_RETRIES ]]; then
        DELAY=${RETRY_DELAYS[$ATTEMPT]}
        echo "WAF block detected (error 15). Retrying in ${DELAY}s... (attempt ${ATTEMPT}/${MAX_RETRIES})" >&2
        sleep $DELAY
        continue
      fi
    fi
    echo "HTTP 403 Forbidden: $RESPONSE" >&2
    exit 1
  elif [[ "$HTTP_CODE" == "429" ]]; then
    echo "Rate limit exceeded. Please wait and retry." >&2
    exit 1
  elif [[ "$HTTP_CODE" == "400" ]]; then
    echo "Bad request: $RESPONSE" >&2
    exit 1
  else
    echo "HTTP ${HTTP_CODE}: $RESPONSE" >&2
    exit 1
  fi
done

if [[ -z "$RESPONSE" ]]; then
  echo "Error: No response received after ${MAX_RETRIES} attempts" >&2
  exit 1
fi

rm -f /tmp/perf_stats_resp.txt

# Apply POP filter if specified (client-side filter on popLatency and originResponseTime)
if [[ -n "$POP" ]]; then
  RESPONSE=$(echo "$RESPONSE" | jq --arg pop "$POP" '
    .data |= map(
      .sitesStatistics |= map(
        .statistics |= (
          if .popLatency then
            .popLatency |= map(
              .pops |= map(select(.pop | test($pop; "i")))
            )
            | .popLatency |= map(select(.pops | length > 0))
          else . end
          | if .originResponseTime then
            .originResponseTime |= map(select(.originPop // "" | test($pop; "i")))
          else . end
        )
      )
    )
  ')
fi

# Output
if [[ "$OUTPUT_FORMAT" == "json" ]]; then
  echo "$RESPONSE" | jq .
else
  # Write jq filter to temp file to avoid shell quoting issues through bws run
  cat > /tmp/perf_stats_format.jq << 'JQEOF'
    "╔══════════════════════════════════════════════════════════════════════╗",
    "║          IMPERVA CWAF — Performance Statistics                     ║",
    "╚══════════════════════════════════════════════════════════════════════╝",
    "",
    "  Timestamp: \(.data[0].timestamp | . / 1000 | strftime("%Y-%m-%d %H:%M:%S UTC"))",
    "  Account ID: \(.data[0].accountId)",
    "",
    "  ┌─────────────────────────────────────────────────────────────────┐",
    "  │  Site Statistics                                                │",
    "  └─────────────────────────────────────────────────────────────────┘",
    "",
    (.data[0].sitesStatistics[] |
      "  ╔══════════════════════════════════════════════════════════════╗",
      "  ║  🌐 \(.siteName) (ID: \(.siteId))",
      "  ╚══════════════════════════════════════════════════════════════╝",
      "",
      # popLatency
      (if .statistics.popLatency then
        "  ┌─ ⚡ PoP Latency (ms) ──────────────────────────────────────┐",
        "  │  Region        │  Avg Latency  │  PoP  │  PoP Latency     │",
        "  │  ──────────────┼───────────────┼───────┼──────────────────│",
        (.statistics.popLatency[] |
          "  │  \(.region | . + " " * (14 - length | if length > 14 then .[0:14] else . end))│  \(.valuePerRegion | tostring | . + " " * (12 - length | if length > 12 then .[0:12] else . end))│  \(.pops[0].pop | . + " " * (5 - length | if length > 5 then .[0:5] else . end))│  \(.pops[0].valuePerPop | tostring | . + " " * (16 - length | if length > 16 then .[0:16] else . end))│"
        ),
        "  └────────────────────────────────────────────────────────────┘",
        ""
      else empty end),
      # originResponseTime
      (if .statistics.originResponseTime then
        "  ┌─ 🖥️  Origin Response Time (ms) ─────────────────────────────┐",
        "  │  Origin Server       │  Data Center      │  PoP  │  Avg RT  │",
        "  │  ────────────────────┼───────────────────┼───────┼──────────│",
        (.statistics.originResponseTime[] |
          "  │  \(.server | . + " " * (20 - length | if length > 20 then .[0:20] else . end))│  \(.dataCenterName // "N/A" | . + " " * (17 - length | if length > 17 then .[0:17] else . end))│  \(.originPop // "N/A" | . + " " * (5 - length | if length > 5 then .[0:5] else . end))│  \(.avgResponseTime | tostring | . + " " * (8 - length | if length > 8 then .[0:8] else . end))│"
        ),
        "  └────────────────────────────────────────────────────────────┘",
        ""
      else empty end),
      # errorResponseTypes
      (if .statistics.errorResponseTypes then
        "  ┌─ ❌ Error Response Types ───────────────────────────────────┐",
        "  │  Error Type                     │  Count                  │",
        "  │  ───────────────────────────────┼─────────────────────────│",
        (.statistics.errorResponseTypes | to_entries[] |
          "  │  \(.key | . + " " * (31 - length | if length > 31 then .[0:31] else . end))│  \(.value | tostring | . + " " * (23 - length | if length > 23 then .[0:23] else . end))│"
        ),
        "  └────────────────────────────────────────────────────────────┘"
      else empty end),
      ""
    )
JQEOF

  echo "$RESPONSE" | jq -r -f /tmp/perf_stats_format.jq
  rm -f /tmp/perf_stats_format.jq
fi
