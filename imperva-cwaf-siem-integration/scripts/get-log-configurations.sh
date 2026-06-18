#!/bin/bash
# Imperva CWAF SIEM Integration — Get Log Configurations
#
# Credential source: Bitwarden (bws run) — DO NOT hardcode
#   IMPERVA_API_ID, IMPERVA_API_KEY injected by bws run
#
# Identifier source: User env vars — DO NOT hardcode in script
#   CAID must be set by user before calling
#
# Usage:
#   List all log configurations:
#     CAID=<caid> bws run --project-id <bw_id> -- bash get-log-configurations.sh
#
#   Get single log configuration:
#     CAID=<caid> CONFIG_ID=<id> bws run --project-id <bw_id> -- bash get-log-configurations.sh
#
#   JSON output:
#     OUTPUT_FORMAT=json CAID=<caid> bws run --project-id <bw_id> -- bash get-log-configurations.sh

CAID="${CAID:-}"
CONFIG_ID="${CONFIG_ID:-}"
OUTPUT_FORMAT="${OUTPUT_FORMAT:-table}"

if [[ -z "$IMPERVA_API_ID" || -z "$IMPERVA_API_KEY" ]]; then
  echo "Error: IMPERVA_API_ID and IMPERVA_API_KEY must be set (via bws run)"
  exit 1
fi

BASE_URL="https://api.imperva.com/siem-config-service/v3/log-configurations"

# Build URL
if [[ -n "$CONFIG_ID" ]]; then
  URL="${BASE_URL}/${CONFIG_ID}"
else
  URL="${BASE_URL}/"
fi

# Build curl command
CURL_CMD="curl -s -G \"${URL}\""
if [[ -n "$CAID" ]]; then
  CURL_CMD+=" --data-urlencode \"caid=${CAID}\""
fi
CURL_CMD+=" -H \"Accept: application/json\""
CURL_CMD+=" -H \"x-API-Id: ${IMPERVA_API_ID}\""
CURL_CMD+=" -H \"x-API-Key: ${IMPERVA_API_KEY}\""

RESPONSE=$(eval "$CURL_CMD")

# Check for errors
if echo "$RESPONSE" | jq -e '.errors' > /dev/null 2>&1; then
  echo "$RESPONSE" | jq .
  exit 1
fi

# Output
if [[ "$OUTPUT_FORMAT" == "json" ]]; then
  echo "$RESPONSE" | jq .
else
  if [[ -n "$CONFIG_ID" ]]; then
    # Single config — show detail
    echo "$RESPONSE" | jq -r '
      .data[] |
      "Config ID:        \(.id)",
      "Name:             \(.configurationName)",
      "Provider:         \(.provider)",
      "Enabled:          \(.enabled)",
      "Format:           \(.format // "N/A")",
      "Compress Logs:    \(.compressLogs // "N/A")",
      "Default Level:    \(.defaultSiteLogsLevel // "N/A")",
      "Public Key:       \(if .publicKey then "Yes (" + (.publicKeyFileName // "embedded") + ")" else "No" end)",
      "Datasets:",
      (.datasets | if length > 0 then map("  - " .) | join("\n") else "  (none)")
    '
  else
    # List — show table
    echo "$RESPONSE" | jq -r '
      ["Config ID", "Name", "Provider", "Enabled", "Datasets"],
      (.data[] | [
        .id,
        .configurationName,
        .provider,
        (.enabled | if . then "Yes" else "No" end),
        (.datasets | join(", "))
      ])
      | @tsv
    ' | awk -F'\t' 'BEGIN {OFS="\t"} {print}' | column -t
  fi
fi
