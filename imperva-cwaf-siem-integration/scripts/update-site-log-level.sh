#!/bin/bash
# Imperva CWAF SIEM Integration — Update Site Log Level
#
# Credential source: Bitwarden (bws run) — DO NOT hardcode
#   IMPERVA_API_ID, IMPERVA_API_KEY injected by bws run
#
# Identifier source: User env vars — DO NOT hardcode in script
#   CAID must be set by user before calling
#
# Usage:
#   Update site log level:
#     SITE_ID=<site_id> LOG_LEVEL=<level> CAID=<caid> bws run -- bash update-site-log-level.sh
#
#   JSON output:
#     SITE_ID=<site_id> LOG_LEVEL=<level> OUTPUT_FORMAT=json CAID=<caid> bws run -- bash update-site-log-level.sh
#
# Valid log levels: full, security, none, default
#   - full:     All logs
#   - security: Security events only
#   - none:     No logs
#   - default:  Account default setting

SITE_ID="${SITE_ID:-}"
LOG_LEVEL="${LOG_LEVEL:-}"
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

if [[ -z "$LOG_LEVEL" ]]; then
  echo "Error: LOG_LEVEL environment variable is required"
  echo "Valid values: full, security, none, default"
  exit 1
fi

# Validate LOG_LEVEL
case "$LOG_LEVEL" in
  full|security|none|default) ;;
  *)
    echo "Error: Invalid LOG_LEVEL '${LOG_LEVEL}'. Valid values: full, security, none, default"
    exit 1
    ;;
esac

BASE_URL="https://my.imperva.com/api/prov/v1/sites/setlog"

URL="${BASE_URL}?site_id=${SITE_ID}&log_level=${LOG_LEVEL}"
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
  RES_MSG=$(echo "$RESPONSE" | jq -r '.res_message // "Unknown error"' 2>/dev/null)
  echo "API Error: res=${RES_CODE} - ${RES_MSG}"
  echo "$RESPONSE" | jq .
  exit 1
fi

NEW_LEVEL=$(echo "$RESPONSE" | jq -r '.debug_info.log_level // "unknown"' 2>/dev/null)

# Output
if [[ "$OUTPUT_FORMAT" == "json" ]]; then
  echo "$RESPONSE" | jq .
else
  echo "Site Log Level Updated"
  echo "─────────────────────"
  echo "Site ID:    ${SITE_ID}"
  echo "Log Level:  ${NEW_LEVEL}"
fi
