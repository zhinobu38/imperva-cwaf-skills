#!/bin/bash
# Get Cache Settings
#
# Credential source: Bitwarden (bws run) — DO NOT hardcode
#   IMPERVA_API_ID, IMPERVA_API_KEY injected by bws run
#
# Identifier source: User env vars — DO NOT hardcode in script
#   SITE_ID must be set by user before calling
#
# Parameters (pass as env vars):
#   SECTIONS — comma-separated sections to retrieve (optional)
#
# Usage:
#   SITE_ID=<id> bws run -- bash get-cache-settings.sh
#   SITE_ID=<id> SECTIONS=mode,client_side bws run -- bash get-cache-settings.sh

SITE_ID="${SITE_ID:?Set SITE_ID}"

URL="https://my.imperva.com/api/prov/v2/sites/${SITE_ID}/settings/cache"
if [ -n "${SECTIONS}" ]; then
  URL="${URL}?sections=${SECTIONS}"
fi

curl -s -X GET "${URL}" \
  -H "Accept: application/json" \
  -H "x-API-Id: ${IMPERVA_API_ID}" \
  -H "x-API-Key: ${IMPERVA_API_KEY}" | jq .
