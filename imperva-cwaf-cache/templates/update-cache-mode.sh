#!/bin/bash
# Update Cache Mode Settings
# Usage: Set environment variables before running via bws run
#   SITE_ID=<siteId> CAID=<caid>

curl -s -X PUT "https://my.imperva.com/api/prov/v2/sites/${SITE_ID}/settings/cache" \
  -H "Accept: application/json" \
  -H "x-API-Id: ${IMPERVA_API_ID}" \
  -H "x-API-Key: ${IMPERVA_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "mode": {
      "level": "smart"
    }
  }' | jq .
