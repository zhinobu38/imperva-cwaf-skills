#!/bin/bash
# Get Certificate Details
#
# Credential source: Bitwarden (bws run) — DO NOT hardcode
#   IMPERVA_API_ID, IMPERVA_API_KEY injected by bws run
#
# Identifier source: User env vars — DO NOT hardcode in script
#   SITE_ID, CAID must be set by user before calling
#
# Usage:
#   SITE_ID=<id> CAID=<caid> bws run -- bash get-certificate-details.sh

SITE_ID="${SITE_ID:?Set SITE_ID}"
CAID="${CAID:?Set CAID}"

curl -s "https://api.imperva.com/certificates-ui/v3/certificates?extSiteId=${SITE_ID}&caid=${CAID}" \
  -H "Accept: application/json" \
  -H "x-API-Id: ${IMPERVA_API_ID}" \
  -H "x-API-Key: ${IMPERVA_API_KEY}" | jq .
