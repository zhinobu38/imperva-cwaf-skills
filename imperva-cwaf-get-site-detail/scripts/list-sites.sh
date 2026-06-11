#!/bin/bash
# Script to list Imperva CWAF sites
# Usage: ./list-sites.sh [caid] [size] [page]
# Example: ./list-sites.sh <YOUR_CAID> 100 0
#
# Environment variables:
#   OUTPUT_FORMAT — table (default) | json
#     table: formatted human-readable table
#     json: raw JSON response (for scripting / jq / grep)
#   SEARCH — keyword to filter sites by name/domain (case-insensitive)
#     When set, only matching sites are shown.

CAID="${CAID:-${1:-<YOUR_CAID>}}"
SIZE="${SIZE:-${2:-100}}"
PAGE="${PAGE:-${3:-0}}"
OUTPUT_FORMAT="${OUTPUT_FORMAT:-table}"
SEARCH="${SEARCH:-}"

API_ID="${IMPERVA_API_ID}"
API_KEY="${IMPERVA_API_KEY}"

if [[ -z "$API_ID" || -z "$API_KEY" ]]; then
  echo "Error: Please set IMPERVA_API_ID and IMPERVA_API_KEY environment variables"
  exit 1
fi

JSON_BODY=$(curl -s -G "https://api.imperva.com/sites-mgmt/v3/sites" \
  --data-urlencode "caid=$CAID" \
  --data-urlencode "size=$SIZE" \
  --data-urlencode "page=$PAGE" \
  -H "Accept: application/json" \
  -H "x-API-Id: $API_ID" \
  -H "x-API-Key: $API_KEY")

# Apply SEARCH filter when set
if [[ -n "$SEARCH" ]]; then
  if [[ "$OUTPUT_FORMAT" == "json" ]]; then
    echo "$JSON_BODY" | jq --arg s "$SEARCH" \
      '.data |= map(select(.name | test($s; "i")))'
  else
    echo "$JSON_BODY" | jq -r --arg s "$SEARCH" '
      ["ID", "Domain/FQDN", "Type", "Status", "Active", "Created", "CNAME"],
      (.data | map(select(.name | test($s; "i"))) | .[] | [
        .id,
        .name,
        .type,
        (.siteStatus // if .active then "ACTIVE" else "INACTIVE" end),
        (.active | if . then "Yes" else "No" end),
        (.creationTime | if . then (. / 1000 | strftime("%Y-%m-%d %H:%M")) else "N/A" end),
        .cname
      ])
      | @tsv
    ' | awk -F'\t' 'BEGIN {OFS="\t"} {print}' | column -t
  fi
else
  if [[ "$OUTPUT_FORMAT" == "json" ]]; then
    echo "$JSON_BODY" | jq .
  else
    echo "$JSON_BODY" | jq -r '
      ["ID", "Domain/FQDN", "Type", "Status", "Active", "Created", "CNAME"],
      (.data[] | [
        .id,
        .name,
        .type,
        (.siteStatus // if .active then "ACTIVE" else "INACTIVE" end),
        (.active | if . then "Yes" else "No" end),
        (.creationTime | if . then (. / 1000 | strftime("%Y-%m-%d %H:%M")) else "N/A" end),
        .cname
      ])
      | @tsv
    ' | awk -F'\t' 'BEGIN {OFS="\t"} {print}' | column -t
  fi
fi
