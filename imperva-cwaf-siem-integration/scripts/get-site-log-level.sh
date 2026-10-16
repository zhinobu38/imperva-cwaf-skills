#!/bin/bash
# Imperva CWAF SIEM Integration — Get Site Log Level
#
# Credential source: Bitwarden (bws run) — DO NOT hardcode
#   IMPERVA_API_ID, IMPERVA_API_KEY injected by bws run
#
# Identifier source: User env vars — DO NOT hardcode in script
#   CAID must be set by user before calling
#
# Usage:
#   Get current log level for a site:
#     SITE_ID=<site_id> CAID=<caid> bws run -- bash get-site-log-level.sh
#
#   JSON output:
#     SITE_ID=<site_id> OUTPUT_FORMAT=json CAID=<caid> bws run -- bash get-site-log-level.sh
#
# Note: Imperva does not have a dedicated GET endpoint for log level.
#       The /api/prov/v1/sites/setlog endpoint accepts log_level="default" (no change)
#       and returns the current setting in debug_info.log_level field.

SITE_ID="${SITE_ID:-}"
OUTPUT_FORMAT="${OUTPUT_FORMAT:-table}"
CAID="${CAID:-}"

if [[ -z "$IMPERVA_API_ID" || -z "$IMPERVA_API_KEY" ]]; then
  echo "Error: IMPERVA_API_ID and IMPERVA_API_KEY must be set (via bws run)"
  exit 1
fi

if [[ -z "$SITE_ID" ]]; then
  echo "Error: SITE_ID environment variable is required"
  exit 1
fi

BASE_URL="https://my.imperva.com/api/prov/v1/sites/setlog"

# Call POST with log_level=default to query current level (no actual change)
URL="${BASE_URL}?site_id=${SITE_ID}&log_level=default"
if [[ -n "$CAID" ]]; then
  URL="${URL}&caid=${CAID}"
fi

RESPONSE=$(curl -s -X POST "$URL" \
  -H "Accept: application/json" \
  -H "x-API-Id: ${IMPERVA_API_ID}" \
  -H "x-API-Key: ${IMPERVA_API_KEY}")

# Check for errors
RES_CODE=$(echo "$RESPONSE" | jq -r '.res // "error"' 2>/dev/null)
if [[ "$RES_CODE" == "error" ]]; then
  echo "$RESPONSE" | jq .
  exit 1
fi

if [[ "$RES_CODE" != "0" ]]; then
  echo "API Error: res=${RES_CODE}"
  echo "$RESPONSE" | jq .
  exit 1
fi

CURRENT_LEVEL=$(echo "$RESPONSE" | jq -r '.debug_info.log_level // "unknown"' 2>/dev/null)

# Output
if [[ "$OUTPUT_FORMAT" == "json" ]]; then
  echo "$RESPONSE" | jq .
else
  echo "Site Log Level"
  echo "─────────────"
  echo "Site ID: ${SITE_ID}"
  echo "Log Level: ${CURRENT_LEVEL}"
fi
