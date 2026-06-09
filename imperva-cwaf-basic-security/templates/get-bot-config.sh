#!/bin/bash
# Get Bot Configuration (v3 - managed bot lists)
#
# Credential source: Bitwarden (bws run) — DO NOT hardcode
#   IMPERVA_API_ID, IMPERVA_API_KEY injected by bws run
#
# Identifier source: User env vars — DO NOT hardcode in template
#   SITE_ID must be set by user before calling
#
# Usage:
#   SITE_ID=<id> bws run --project-id <bw_id> -- bash get-bot-config.sh

SITE_ID="${SITE_ID:?Set SITE_ID (from user input or imperva-cwaf-get-site-detail)}"

curl -s -X GET "https://my.imperva.com/api/prov/v3/sites/${SITE_ID}/settings/botConfiguration" \
  -H "Accept: application/json" \
  -H "x-API-Id: ${IMPERVA_API_ID}" \
  -H "x-API-Key: ${IMPERVA_API_KEY}" | jq .
