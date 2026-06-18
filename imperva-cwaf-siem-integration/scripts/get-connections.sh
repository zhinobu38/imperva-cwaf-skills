#!/bin/bash
# Imperva CWAF SIEM Integration — Get Connections
#
# Credential source: Bitwarden (bws run) — DO NOT hardcode
#   IMPERVA_API_ID, IMPERVA_API_KEY injected by bws run
#
# Identifier source: User env vars — DO NOT hardcode in script
#   CAID must be set by user before calling
#
# Usage:
#   List all connections:
#     CAID=<caid> bws run --project-id <bw_id> -- bash get-connections.sh
#
#   Get single connection:
#     CAID=<caid> CONNECTION_ID=<id> bws run --project-id <bw_id> -- bash get-connections.sh
#
#   JSON output:
#     OUTPUT_FORMAT=json CAID=<caid> bws run --project-id <bw_id> -- bash get-connections.sh

CAID="${CAID:-}"
CONNECTION_ID="${CONNECTION_ID:-}"
OUTPUT_FORMAT="${OUTPUT_FORMAT:-table}"

if [[ -z "$IMPERVA_API_ID" || -z "$IMPERVA_API_KEY" ]]; then
  echo "Error: IMPERVA_API_ID and IMPERVA_API_KEY must be set (via bws run)"
  exit 1
fi

BASE_URL="https://api.imperva.com/siem-config-service/v3/connections"

# Build URL
if [[ -n "$CONNECTION_ID" ]]; then
  URL="${BASE_URL}/${CONNECTION_ID}"
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
  if [[ -n "$CONNECTION_ID" ]]; then
    # Single connection — show detail
    echo "$RESPONSE" | jq -r '
      .data[] |
      "Connection ID:    \(.id)",
      "Name:             \(.connectionName)",
      "Asset ID:         \(.assetId // "N/A")",
      "Storage Type:     \(.storageType)",
      "Connection Info:",
      (if .storageType == "CUSTOMER_S3" then
        "  Access Key:    \(.connectionInfo.accessKey // "N/A")\n  Secret Key:    **** (hidden)\n  Path:          \(.connectionInfo.path // "N/A")"
      elif .storageType == "CUSTOMER_S3_ARN" then
        "  Path (ARN):    \(.connectionInfo.path // "N/A")"
      elif .storageType == "CUSTOMER_SFTP" then
        "  Host:          \(.connectionInfo.host // "N/A")\n  Username:      \(.connectionInfo.username // "N/A")\n  Password:      **** (hidden)\n  Path:          \(.connectionInfo.path // "N/A")"
      elif .storageType == "CUSTOMER_SPLUNK" then
        "  Host:          \(.connectionInfo.host // "N/A")\n  Port:          \(.connectionInfo.port // "N/A")\n  Token:         **** (hidden)"
      else
        "  (unknown storage type)"
      end)
    '
  else
    # List — show table
    echo "$RESPONSE" | jq -r '
      ["Connection ID", "Name", "Storage Type", "Asset ID"],
      (.data[] | [
        .id,
        .connectionName,
        .storageType,
        (.assetId // "N/A")
      ])
      | @tsv
    ' | awk -F'\t' 'BEGIN {OFS="\t"} {print}' | column -t
  fi
fi
