#!/bin/bash
# Get Delivery Settings
#
# Credential source: Bitwarden (bws run) — DO NOT hardcode
#   IMPERVA_API_ID, IMPERVA_API_KEY injected by bws run
#
# Identifier source: User env vars — DO NOT hardcode in template
#   SITE_ID, CAID must be set by user before calling
#
# Usage:
#   SITE_ID=<id> CAID=<caid> bws run --project-id <bw_project_id> -- bash get-delivery.sh
#   SITE_ID=<id> CAID=<caid> SECTIONS=compression,network bws run ... -- bash get-delivery.sh

SITE_ID="${SITE_ID:?Set SITE_ID (from user input or imperva-cwaf-get-site-detail)}"
CAID="${CAID:?Set CAID (from user input or imperva-cwaf-get-site-detail)}"

ARGS="caid=${CAID}"
if [ -n "${SECTIONS}" ]; then
  ARGS="${ARGS}&sections=${SECTIONS}"
fi

curl -s -X GET "https://my.imperva.com/api/prov/v2/sites/${SITE_ID}/settings/delivery?${ARGS}" \
  -H "Accept: application/json" \
  -H "x-API-Id: ${IMPERVA_API_ID}" \
  -H "x-API-Key: ${IMPERVA_API_KEY}" | jq .
