#!/bin/bash
# Imperva CWAF Policy Management — Create a new policy
#
# Credential source: Bitwarden (bws run) — DO NOT hardcode
#   IMPERVA_API_ID, IMPERVA_API_KEY injected by bws run
#
# Identifier source: User env vars — DO NOT hardcode in template
#   CAID must be set by user before calling
#
# Parameters (pass as env vars):
#   POLICY_NAME — policy name (required)
#   POLICY_TYPE — WAF_RULES | ACL | WHITELIST | FILE_UPLOAD (required)
#   POLICY_DESC — description (optional)
#   ENABLED     — true | false (default: true)
#
# Usage:
#   CAID=<caid> POLICY_NAME="Block RU" POLICY_TYPE=ACL bws run -- bash create-policy.sh

CAID="${CAID:?Set CAID}"
POLICY_NAME="${POLICY_NAME:?Set POLICY_NAME}"
POLICY_TYPE="${POLICY_TYPE:?Set POLICY_TYPE (WAF_RULES|ACL|WHITELIST|FILE_UPLOAD)}"
POLICY_DESC="${POLICY_DESC:-}"
ENABLED="${ENABLED:-true}"

curl -s -X POST "https://api.imperva.com/policies/v2/policies?caid=${CAID}" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -H "x-API-Id: ${IMPERVA_API_ID}" \
  -H "x-API-Key: ${IMPERVA_API_KEY}" \
  -d "{
    \"name\": \"${POLICY_NAME}\",
    \"policyType\": \"${POLICY_TYPE}\",
    \"description\": \"${POLICY_DESC}\",
    \"enabled\": ${ENABLED}
  }" | jq '{ id: .value.id, name: .value.name, policyType: .value.policyType, enabled: .value.enabled, isError: .isError }'
