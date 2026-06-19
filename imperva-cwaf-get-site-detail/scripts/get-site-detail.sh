#!/bin/bash
# Imperva CWAF — Get site detail by site ID
#
# Credential source: Bitwarden (bws run) — DO NOT hardcode
#   IMPERVA_API_ID, IMPERVA_API_KEY injected by bws run
#
# Parameters (pass as env vars):
#   CAID     — Imperva account ID
#   SITE_ID  — Site ID (from list-sites or onboard response)
#
# Usage:
#   CAID=<caid> SITE_ID=<site_id> bws run --project-id <bw_id> -- bash get-site-detail.sh

CAID="${CAID:?Set CAID}"
SITE_ID="${SITE_ID:?Set SITE_ID}"

RESPONSE=$(curl -s -X GET "https://api.imperva.com/sites-mgmt/v3/sites/${SITE_ID}?caid=${CAID}" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -H "x-API-Id: ${IMPERVA_API_ID}" \
  -H "x-API-Key: ${IMPERVA_API_KEY}")

# Check for error response (v3 uses {"errors":[...]} format)
if echo "${RESPONSE}" | jq -e '.errors' > /dev/null 2>&1; then
  echo "${RESPONSE}" | jq '{error: .errors[0]}'
else
  echo "${RESPONSE}" | jq '{
    siteId: .id,
    name: .name,
    domain: .domain,
    cname: .cname,
    siteStatus: .siteStatus,
    active: .active
  }'
fi
