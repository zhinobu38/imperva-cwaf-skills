#!/bin/bash
# Enable SSL Certificate (Imperva-Managed)
#
# Credential source: Bitwarden (bws run) — DO NOT hardcode
#   IMPERVA_API_ID, IMPERVA_API_KEY injected by bws run
#
# Identifier source: User env vars — DO NOT hardcode in template
#   SITE_ID, CAID must be set by user before calling
#
# Usage:
#   SITE_ID=<id> CAID=<caid> bws run --project-id <bw_id> -- bash enable-ssl.sh

SITE_ID="${SITE_ID:?Set SITE_ID}"
CAID="${CAID:?Set CAID}"

curl -s -X PUT "https://api.imperva.com/sites-mgmt/v3/sites/${SITE_ID}/certificates/managed?caid=${CAID}" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -H "x-API-Id: ${IMPERVA_API_ID}" \
  -H "x-API-Key: ${IMPERVA_API_KEY}" \
  -d '{"siteCertificateEnabled": true, "defaultValidationMethod": "CNAME"}' | jq .

