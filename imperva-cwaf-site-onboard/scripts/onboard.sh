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
#   CAID           — Imperva account ID
#   DOMAIN         — FQDN to onboard (e.g. example.com)
#   ORIGIN_IP      — Origin server IP address
#   SITE_NAME      — Friendly name (default: same as DOMAIN)
#   GENERATE_CERT  — true | false (default: true)
#
# Usage:
#   CAID=<caid> DOMAIN=example.com ORIGIN_IP=203.0.113.50 \
#     bws run --project-id <bw_id> -- bash onboard.sh

CAID="${CAID:?Set CAID}"
DOMAIN="${DOMAIN:?Set DOMAIN (FQDN to onboard)}"
ORIGIN_IP="${ORIGIN_IP:?Set ORIGIN_IP (origin server IP)}"
SITE_NAME="${SITE_NAME:-$DOMAIN}"
GENERATE_CERT="${GENERATE_CERT:-true}"

# Build payload safely with jq to avoid shell escaping issues
PAYLOAD=$(jq -n \
  --arg domain "$DOMAIN" \
  --arg name "$SITE_NAME" \
  --arg ip "$ORIGIN_IP" \
  --arg gen "$GENERATE_CERT" \
  '{
    domain: $domain,
    name: $name,
    servers: [$ip],
    generateCertificate: ($gen == "true"),
    type: "CLOUD_WAF"
  }')

RESPONSE=$(curl -s -X POST "https://api.imperva.com/sites-mgmt/v3/sites/onboard?caid=${CAID}" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -H "x-API-Id: ${IMPERVA_API_ID}" \
  -H "x-API-Key: ${IMPERVA_API_KEY}" \
  -d "${PAYLOAD}")

# Check for error response — v3 uses both {"errors":[...]} and {"error":{...}} formats
if echo "${RESPONSE}" | jq -e '.errors' > /dev/null 2>&1; then
  # Array error format: {"errors":[{"status":400,"title":"...","detail":"..."}]}
  echo "${RESPONSE}" | jq '{error: .errors[0]}'
elif echo "${RESPONSE}" | jq -e '.error' > /dev/null 2>&1; then
  # Object error format: {"error":{"status":400,"title":"...","detail":"..."}}
  echo "${RESPONSE}" | jq '{error: .error}'
elif echo "${RESPONSE}" | jq -e '.errorCode' > /dev/null 2>&1; then
  # WAF block format: {"errorCode":"15","description":"This request was blocked..."}
  echo "${RESPONSE}" | jq '{error: {title: "WAF_BLOCKED", detail: .description, errorCode: .errorCode}}'
elif echo "${RESPONSE}" | jq -e '.data' > /dev/null 2>&1; then
  # Success format: {"data":[{"site":{"id":...,"name":...,"cname":...},"domains":[...]}]}
  echo "${RESPONSE}" | jq '{
    siteId: .data[0].site.id,
    name: .data[0].site.name,
    domain: .data[0].domains[0].name,
    cname: .data[0].site.cname,
    siteStatus: .data[0].domains[0].protectionStatus,
    active: .data[0].site.active
  }'
else
  echo "UNKNOWN RESPONSE FORMAT:" >&2
  echo "${RESPONSE}" | jq .
  echo "${RESPONSE}" | jq '{
    siteId: .data[0].id,
    name: .data[0].name,
    domain: .data[0].domain,
    cname: .data[0].cname,
    siteStatus: .data[0].siteStatus,
    active: .data[0].active
  }'
fi
