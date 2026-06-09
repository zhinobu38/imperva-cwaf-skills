#!/bin/bash
# Create a Cache Rule
#
# Credential source: Bitwarden (bws run) — DO NOT hardcode
#   IMPERVA_API_ID, IMPERVA_API_KEY injected by bws run
#
# Identifier source: User env vars — DO NOT hardcode in template
#   SITE_ID, CAID must be set by user before calling
#
# Parameters (pass as env vars):
#   RULE_NAME   — rule name
#   RULE_ACTION — HTTP_CACHE_MAKE_STATIC | HTTP_CACHE_CLIENT_CACHE_CTL | HTTP_CACHE_FORCE_UNCACHEABLE | etc.
#   RULE_FILTER — filter expression (e.g. 'URL contains ".css"')
#   RULE_TTL    — TTL in seconds (optional, for MAKE_STATIC and CLIENT_CACHE_CTL)
#
# Usage:
#   SITE_ID=<id> CAID=<caid> RULE_NAME=CacheStatic RULE_ACTION=HTTP_CACHE_MAKE_STATIC RULE_FILTER='URL contains ".css"' RULE_TTL=86400 bws run --project-id <bw_id> -- bash create-cache-rule.sh

SITE_ID="${SITE_ID:?Set SITE_ID}"
CAID="${CAID:?Set CAID}"
RULE_NAME="${RULE_NAME:?Set RULE_NAME}"
RULE_ACTION="${RULE_ACTION:?Set RULE_ACTION}"
RULE_FILTER="${RULE_FILTER:-}"
RULE_TTL="${RULE_TTL:-}"

# Build rule JSON
BODY="{\"name\": \"${RULE_NAME}\", \"action\": \"${RULE_ACTION}\", \"enabled\": true"
if [ -n "${RULE_FILTER}" ]; then
  BODY="${BODY}, \"filter\": \"${RULE_FILTER}\""
fi
if [ -n "${RULE_TTL}" ]; then
  BODY="${BODY}, \"ttl\": ${RULE_TTL}"
fi
BODY="${BODY}}"

curl -s -X POST "https://my.imperva.com/api/prov/v2/sites/${SITE_ID}/settings/cache/rules" \
  -H "Accept: application/json" \
  -H "x-API-Id: ${IMPERVA_API_ID}" \
  -H "x-API-Key: ${IMPERVA_API_KEY}" \
  -H "Content-Type: application/json" \
  -d "${BODY}" | jq .

