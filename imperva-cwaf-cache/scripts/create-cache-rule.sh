#!/bin/bash
# Create a Cache Rule
#
# Credential source: Bitwarden (bws run) — DO NOT hardcode
#   IMPERVA_API_ID, IMPERVA_API_KEY injected by bws run
#
# Identifier source: User env vars — DO NOT hardcode in script
#   SITE_ID must be set by user before calling
#
# Parameters (pass as env vars):
#   RULE_NAME    — rule name
#   RULE_ACTION  — HTTP_CACHE_MAKE_STATIC | HTTP_CACHE_CLIENT_CACHE_CTL | HTTP_CACHE_FORCE_UNCACHEABLE | etc.
#   RULE_FILTER  — filter expression (e.g. 'URL contains ".css"')
#   RULE_TTL     — TTL in seconds (optional, for MAKE_STATIC and CLIENT_CACHE_CTL)
#   RULE_ENABLED — true | false (default: true)
#
# Usage:
#   SITE_ID=<id> RULE_NAME=CacheStatic RULE_ACTION=HTTP_CACHE_MAKE_STATIC \
#     RULE_FILTER='URL contains ".css"' RULE_TTL=86400 \
#     bws run -- bash create-cache-rule.sh

SITE_ID="${SITE_ID:?Set SITE_ID}"
RULE_NAME="${RULE_NAME:?Set RULE_NAME}"
RULE_ACTION="${RULE_ACTION:?Set RULE_ACTION}"
RULE_FILTER="${RULE_FILTER:-}"
RULE_TTL="${RULE_TTL:-}"
RULE_ENABLED="${RULE_ENABLED:-true}"

# Build JSON body using jq for safe escaping
JSON_BODY=$(jq -n \
  --arg name "${RULE_NAME}" \
  --arg action "${RULE_ACTION}" \
  --arg filter "${RULE_FILTER}" \
  --argjson enabled "${RULE_ENABLED}" \
  --argjson ttl "${RULE_TTL:-null}" '
  {
    name: $name,
    action: $action,
    enabled: $enabled,
    filter: $filter
  } + (if $ttl != null then {ttl: $ttl} else {} end)
')

curl -s -X POST "https://my.imperva.com/api/prov/v2/sites/${SITE_ID}/settings/cache/rules" \
  -H "Accept: application/json" \
  -H "x-API-Id: ${IMPERVA_API_ID}" \
  -H "x-API-Key: ${IMPERVA_API_KEY}" \
  -H "Content-Type: application/json" \
  -d "${JSON_BODY}" | jq .
