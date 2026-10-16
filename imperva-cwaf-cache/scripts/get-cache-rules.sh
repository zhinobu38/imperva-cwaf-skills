#!/bin/bash
# Get Cache Rules (list all)
#
# Credential source: Bitwarden (bws run) — DO NOT hardcode
#   IMPERVA_API_ID, IMPERVA_API_KEY injected by bws run
#
# Identifier source: User env vars — DO NOT hardcode in script
#   SITE_ID must be set by user before calling
#
# Usage:
#   SITE_ID=<id> bws run -- bash get-cache-rules.sh

SITE_ID="${SITE_ID:?Set SITE_ID}"

curl -s -X GET "https://my.imperva.com/api/prov/v2/sites/${SITE_ID}/settings/cache/rules" \
  -H "Accept: application/json" \
  -H "x-API-Id: ${IMPERVA_API_ID}" \
  -H "x-API-Key: ${IMPERVA_API_KEY}" | jq .
