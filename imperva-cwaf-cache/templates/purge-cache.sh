#!/bin/bash
# Purge Cache by URL Pattern
# Usage: Set environment variables before running via bws run
#   SITE_ID=<siteId> CAID=<caid>
#   URL_PATTERN=<pattern> (optional — omit to purge all)

if [ -n "${URL_PATTERN}" ]; then
  curl -s -X DELETE "https://my.imperva.com/api/prov/v2/sites/${SITE_ID}/cache?url_pattern=${URL_PATTERN}" \
    -H "Accept: application/json" \
    -H "x-API-Id: ${IMPERVA_API_ID}" \
    -H "x-API-Key: ${IMPERVA_API_KEY}" | jq .
else
  curl -s -X DELETE "https://my.imperva.com/api/prov/v2/sites/${SITE_ID}/cache" \
    -H "Accept: application/json" \
    -H "x-API-Id: ${IMPERVA_API_ID}" \
    -H "x-API-Key: ${IMPERVA_API_KEY}" | jq .
fi
