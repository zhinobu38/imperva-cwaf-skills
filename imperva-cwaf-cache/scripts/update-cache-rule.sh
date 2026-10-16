#!/bin/bash
# Update a Cache Rule — GET → modify → PUT full object
#
# Credential source: Bitwarden (bws run) — DO NOT hardcode
#   IMPERVA_API_ID, IMPERVA_API_KEY injected by bws run
#
# Identifier source: User env vars — DO NOT hardcode in script
#   SITE_ID, RULE_ID must be set by user before calling
#
# Parameters (pass as env vars) — only set fields you want to change:
#   RULE_NAME    — new name (optional)
#   RULE_ACTION  — new action (optional)
#   RULE_FILTER  — new filter expression (optional)
#   RULE_TTL     — new TTL in seconds (optional, pass "null" to remove)
#   RULE_ENABLED — true | false (optional)
#
# Usage:
#   SITE_ID=<id> RULE_ID=<id> RULE_ENABLED=false \
#     bws run -- bash update-cache-rule.sh

SITE_ID="${SITE_ID:?Set SITE_ID}"
RULE_ID="${RULE_ID:?Set RULE_ID}"

BASE_URL="https://my.imperva.com/api/prov/v2/sites/${SITE_ID}/settings/cache/rules/${RULE_ID}"

# 1. GET current rule
CURRENT=$(curl -s -X GET "${BASE_URL}" \
  -H "Accept: application/json" \
  -H "x-API-Id: ${IMPERVA_API_ID}" \
  -H "x-API-Key: ${IMPERVA_API_KEY}")

# 2. Build jq modification expression dynamically
JQ_FILTER="."
[ -n "${RULE_NAME}" ]   && JQ_FILTER="${JQ_FILTER} | .name = \"${RULE_NAME}\""
[ -n "${RULE_ACTION}" ] && JQ_FILTER="${JQ_FILTER} | .action = \"${RULE_ACTION}\""
[ -n "${RULE_FILTER}" ] && JQ_FILTER="${JQ_FILTER} | .filter = \"${RULE_FILTER}\""
[ -n "${RULE_TTL}" ]    && JQ_FILTER="${JQ_FILTER} | .ttl = ${RULE_TTL}"
[ -n "${RULE_ENABLED}" ] && JQ_FILTER="${JQ_FILTER} | .enabled = ${RULE_ENABLED}"

MODIFIED=$(echo "${CURRENT}" | jq "${JQ_FILTER}")

# 3. PUT full object with Force-Risky-Operation header
curl -s -X PUT "${BASE_URL}" \
  -H "Accept: application/json" \
  -H "x-API-Id: ${IMPERVA_API_ID}" \
  -H "x-API-Key: ${IMPERVA_API_KEY}" \
  -H "Content-Type: application/json" \
  -H "Force-Risky-Operation: true" \
  -d "${MODIFIED}" | jq .
