#!/bin/bash
# Get Site Security Configuration
# Endpoint: POST https://my.imperva.com/api/prov/v1/sites/status
# Returns: security.waf.rules[] — backdoor, DDoS, bot control, and other WAF rules
#
# Credential source: Bitwarden (bws run) — DO NOT hardcode
#   IMPERVA_API_ID, IMPERVA_API_KEY injected by bws run
#
# Identifier source: User env vars — DO NOT hardcode in template
#   SITE_ID, CAID must be set by user before calling
#
# Usage:
#   SITE_ID=<id> CAID=<caid> bws run -- bash get-security.sh

SITE_ID="${SITE_ID:?Set SITE_ID (from user input or imperva-cwaf-get-site-detail)}"
CAID="${CAID:?Set CAID (from user input or imperva-cwaf-get-site-detail)}"

# POST /sites/status — response contains .security.waf.rules[] with all security rules
curl -s -X POST "https://my.imperva.com/api/prov/v1/sites/status" \
  -H "Accept: application/json" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -H "x-API-Id: ${IMPERVA_API_ID}" \
  -H "x-API-Key: ${IMPERVA_API_KEY}" \
  --data-urlencode "site_id=${SITE_ID}" \
  --data-urlencode "caid=${CAID}" | jq '.security'
