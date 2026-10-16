#!/bin/bash
# Imperva CWAF Policy Management — Update a policy (name, description, enabled)
#
# Credential source: Bitwarden (bws run) — DO NOT hardcode
#   IMPERVA_API_ID, IMPERVA_API_KEY injected by bws run
#
# Identifier source: User env vars — DO NOT hardcode in template
#   CAID, POLICY_ID must be set by user before calling
#
# Parameters (pass as env vars — all optional, only specified fields are updated):
#   POLICY_NAME  — new policy name
#   POLICY_DESC  — new description
#   ENABLED      — true | false
#
# Usage:
#   CAID=<caid> POLICY_ID=<id> POLICY_NAME="New Name" bws run -- bash update-policy.sh
#   CAID=<caid> POLICY_ID=<id> ENABLED=false bws run -- bash update-policy.sh

CAID="${CAID:?Set CAID}"
POLICY_ID="${POLICY_ID:?Set POLICY_ID}"

# Build update JSON — only include fields that are set
UPDATE='{}'
[ -n "${POLICY_NAME}" ] && UPDATE=$(echo "$UPDATE" | jq --arg v "${POLICY_NAME}" '.name = $v')
[ -n "${POLICY_DESC}" ] && UPDATE=$(echo "$UPDATE" | jq --arg v "${POLICY_DESC}" '.description = $v')
[ -n "${ENABLED}" ] && UPDATE=$(echo "$UPDATE" | jq --arg v "${ENABLED}" '.enabled = ($v == "true")')

# If nothing to update, exit
UPDATE_COUNT=$(echo "$UPDATE" | jq 'keys | length')
if [ "$UPDATE_COUNT" -eq 0 ]; then
  echo '{"value":"No fields specified. Provide POLICY_NAME, POLICY_DESC, or ENABLED.","isError":true}'
  exit 1
fi

curl -s -X POST "https://api.imperva.com/policies/v2/policies/${POLICY_ID}?caid=${CAID}" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -H "x-API-Id: ${IMPERVA_API_ID}" \
  -H "x-API-Key: ${IMPERVA_API_KEY}" \
  -d "${UPDATE}" | jq .
