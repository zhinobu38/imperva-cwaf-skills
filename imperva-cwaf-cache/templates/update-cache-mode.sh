#!/bin/bash
# Update Cache Mode Settings
# Usage: Set SITE_ID env var, then run via bws run
#
# Examples:
#   Set mode to smart:     mode_level=smart
#   Set mode to standard:  mode_level=standard
#   Disable caching:       mode_level=disabled

MODE_LEVEL="${MODE_LEVEL:-smart}"

curl -s -X PUT "https://my.imperva.com/api/prov/v2/sites/${SITE_ID}/settings/cache" \
  -H "Accept: application/json" \
  -H "x-API-Id: ${IMPERVA_API_ID}" \
  -H "x-API-Key: ${IMPERVA_API_KEY}" \
  -H "Content-Type: application/json" \
  -d "{\"mode\":{\"level\":\"${MODE_LEVEL}\"}}" | jq .
