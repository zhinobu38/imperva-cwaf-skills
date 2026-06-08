#!/bin/bash
# Script to list Imperva CWAF sites in a formatted table
# Usage: ./list-sites.sh [caid] [size] [page]
# Example: ./list-sites.sh <YOUR_CAID> 100 0

CAID="${1:-<YOUR_CAID>}"
SIZE="${2:-100}"
PAGE="${3:-0}"

API_ID="${IMPERVA_API_ID}"
API_KEY="${IMPERVA_API_KEY}"

if [[ -z "$API_ID" || -z "$API_KEY" ]]; then
  echo "Error: Please set IMPERVA_API_ID and IMPERVA_API_KEY environment variables"
  exit 1
fi

curl -s -G "https://api.imperva.com/sites-mgmt/v3/sites" \
  --data-urlencode "caid=$CAID" \
  --data-urlencode "size=$SIZE" \
  --data-urlencode "page=$PAGE" \
  -H "Accept: application/json" \
  -H "x-API-Id: $API_ID" \
  -H "x-API-Key: $API_KEY" \
| jq -r '
  (["ID", "Domain/FQDN", "Type", "Status", "Active", "Created", "CNAME"]),
  (.data[] | [
    .id,
    .name,
    .type,
    (.siteStatus // if .active then "ACTIVE" else "INACTIVE" end),
    (.active | if . then "Yes" else "No" end),
    (.creationTime | if . then (. / 1000 | strftime("%Y-%m-%d %H:%M")) else "N/A" end),
    .cname
  ])
| @tsv' | column -t -s $'\t'