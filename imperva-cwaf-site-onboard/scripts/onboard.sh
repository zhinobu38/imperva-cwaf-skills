#!/bin/bash
# Imperva CWAF — Onboard a new site
#
# Credential source: Bitwarden (bws run) — DO NOT hardcode
#   IMPERVA_API_ID, IMPERVA_API_KEY injected by bws run
#
# Identifier source: User env vars — DO NOT hardcode in template
#   CAID, DOMAIN, ORIGIN_IP must be set by user before calling
#
# Parameters (pass as env vars):
#   CAID        — Imperva account ID
#   DOMAIN      — FQDN to onboard (e.g. example.com)
#   ORIGIN_IP   — Origin server IP address
#   SITE_NAME   — Friendly name (default: same as DOMAIN)
#   GENERATE_CERT — true | false (default: true)
#
# Usage:
#   CAID=<caid> DOMAIN=example.com ORIGIN_IP=203.0.113.50 \
#     bws run --project-id <bw_id> -- bash onboard.sh

CAID="${CAID:?Set CAID}"
DOMAIN="${DOMAIN:?Set DOMAIN (FQDN to onboard)}"
ORIGIN_IP="${ORIGIN_IP:?Set ORIGIN_IP (origin server IP)}"
SITE_NAME="${SITE_NAME:-$DOMAIN}"
GENERATE_CERT="${GENERATE_CERT:-true}"

curl -s -X POST "https://api.imperva.com/sites-mgmt/v3/sites/onboard?caid=${CAID}" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -H "x-API-Id: ${IMPERVA_API_ID}" \
  -H "x-API-Key: ${IMPERVA_API_KEY}" \
  -d "{
    \"domain\": \"${DOMAIN}\",
    \"name\": \"${SITE_NAME}\",
    \"servers\": [\"${ORIGIN_IP}\"],
    \"generateCertificate\": ${GENERATE_CERT},
    \"type\": \"CLOUD_WAF\"
  }" | jq '{
    siteId: .data[0].id,
    name: .data[0].name,
    domain: .data[0].domain,
    cname: .data[0].cname,
    siteStatus: .data[0].siteStatus,
    active: .data[0].active
  }'
