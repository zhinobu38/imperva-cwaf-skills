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

# Fetch data
RESPONSE=$(curl -s --get "$URL" \
  --data-urlencode "caid=${CAID}" \
  -H "Accept: application/json" \
  -H "x-API-Id: ${IMPERVA_API_ID}" \
  -H "x-API-Key: ${IMPERVA_API_KEY}")

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
      "Connection ID:    \(.connectionId // "N/A")",
      "Public Key:       \(if .publicKey then "Yes (" + (.publicKeyFileName // "embedded") + ")" else "No" end)",
      "Datasets:",
      (.datasets | if length > 0 then map("  - " .) | join("\n") else "  (none)")
    '
  else
    # List — show table
    COUNT=$(echo "$RESPONSE" | jq '.data | length')
    if [[ "$COUNT" -eq 0 ]]; then
      echo "No log configurations found."
    else
      printf "%-24s %-35s %-18s %-8s\n" "Config ID" "Name" "Provider" "Enabled"
      printf "%-24s %-35s %-18s %-8s\n" "─" "─" "─" "─" | tr ' ' '─'
      echo "$RESPONSE" | jq -r '
        .data[] | [.id, .configurationName, .provider, (.enabled | if . then "Yes" else "No" end)] | @tsv
      ' | while IFS=$'\t' read -r id name provider enabled; do
        printf "%-24s %-35s %-18s %-8s\n" "$id" "$name" "$provider" "$enabled"
      done
    fi
  fi
fi
