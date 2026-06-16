#!/bin/bash
# Purge Cache by URL Pattern or Purge All
#
# Credential source: Bitwarden (bws run) — DO NOT hardcode
#   IMPERVA_API_ID, IMPERVA_API_KEY injected by bws run
#
# Identifier source: User env vars — DO NOT hardcode in script
#   SITE_ID must be set by user before calling
#
# Parameters (pass as env vars):
#   URL_PATTERN — URL pattern to purge (optional — omit to purge all)
#
# Pattern syntax:
#   resource_name     — resources containing the name
#   ^resource_name    — resources starting with the name
#   resource_name$    — resources ending with the name
#
# Usage:
#   SITE_ID=<id> URL_PATTERN=style.css bws run --project-id <bw_id> -- bash purge-cache.sh
#   SITE_ID=<id> bws run --project-id <bw_id> -- bash purge-cache.sh

SITE_ID="${SITE_ID:?Set SITE_ID}"

if [ -n "${URL_PATTERN}" ]; then
  curl -s -X DELETE "https://my.imperva.com/api/prov/v2/sites/${SITE_ID}/cache" \
    -H "Accept: application/json" \
    -H "x-API-Id: ${IMPERVA_API_ID}" \
    -H "x-API-Key: ${IMPERVA_API_KEY}" \
    --data-urlencode "url_pattern=${URL_PATTERN}" | jq .
else
  curl -s -X DELETE "https://my.imperva.com/api/prov/v2/sites/${SITE_ID}/cache" \
    -H "Accept: application/json" \
    -H "x-API-Id: ${IMPERVA_API_ID}" \
    -H "x-API-Key: ${IMPERVA_API_KEY}" | jq .
fi
