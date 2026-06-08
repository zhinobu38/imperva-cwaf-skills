#!/bin/bash
# Create a Cache Rule
# Usage: Set environment variables before running via bws run
#   SITE_ID=<siteId> CAID=<caid>

curl -s -X POST "https://my.imperva.com/api/prov/v2/sites/${SITE_ID}/settings/cache/rules" \
  -H "Accept: application/json" \
  -H "x-API-Id: ${IMPERVA_API_ID}" \
  -H "x-API-Key: ${IMPERVA_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Cache Static Assets",
    "action": "HTTP_CACHE_MAKE_STATIC",
    "enabled": true,
    "filter": "URL contains \".css\" | URL contains \".js\" | URL contains \".png\"",
    "ttl": 86400
  }' | jq .
