#!/bin/bash
# Imperva CWAF Policy Management — List policies applied to a site
#
# Credential source: Bitwarden (bws run) — DO NOT hardcode
#   IMPERVA_API_ID, IMPERVA_API_KEY injected by bws run
#
# Identifier source: User env vars — DO NOT hardcode in template
#   SITE_ID must be set by user before calling
#
# Usage:
#   SITE_ID=<id> bws run -- bash list-site-policies.sh

SITE_ID="${SITE_ID:?Set SITE_ID}"

curl -s -G "https://api.imperva.com/policies/v2/assets/WEBSITE/${SITE_ID}/policies?extended=true" \
  -H "Accept: application/json" \
  -H "x-API-Id: ${IMPERVA_API_ID}" \
  -H "x-API-Key: ${IMPERVA_API_KEY}" | jq .
