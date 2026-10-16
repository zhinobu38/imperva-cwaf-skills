#!/bin/bash
# Imperva CWAF — Get site CNAME (for DNS configuration after onboarding)
#
# Credential source: Bitwarden (bws run) — DO NOT hardcode
#   IMPERVA_API_ID, IMPERVA_API_KEY injected by bws run
#
# Identifier source: User env vars — DO NOT hardcode in template
#   SITE_ID, CAID must be set by user before calling
#
# Usage:
#   SITE_ID=<id> CAID=<caid> bws run -- bash get-site-cname.sh
#
# Note: imperva-cwaf-get-site-detail returns the same fields (cname, siteStatus, active).
# This script is a lightweight alternative when you already have SITE_ID.

SITE_ID="${SITE_ID:?Set SITE_ID}"
CAID="${CAID:?Set CAID}"

curl -s -G "https://api.imperva.com/sites-mgmt/v3/sites/${SITE_ID}?caid=${CAID}" \
  -H "Accept: application/json" \
  -H "x-API-Id: ${IMPERVA_API_ID}" \
  -H "x-API-Key: ${IMPERVA_API_KEY}" | jq '{
    siteId: .data[0].site.id,
    name: .data[0].site.name,
    cname: .data[0].site.cname,
    siteStatus: .data[0].domains[0].protectionStatus,
    active: .data[0].site.active
  }'
