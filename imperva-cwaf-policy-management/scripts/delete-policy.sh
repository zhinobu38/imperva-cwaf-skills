#!/bin/bash
# Imperva CWAF Policy Management — Delete a policy
# IMPORTANT: Remove from all sites first before deleting!
#
# Credential source: Bitwarden (bws run) — DO NOT hardcode
#   IMPERVA_API_ID, IMPERVA_API_KEY injected by bws run
#
# Identifier source: User env vars — DO NOT hardcode in template
#   CAID, POLICY_ID must be set by user before calling
#
# Usage:
#   CAID=<caid> POLICY_ID=<id> bws run --project-id <bw_id> -- bash delete-policy.sh

CAID="${CAID:?Set CAID}"
POLICY_ID="${POLICY_ID:?Set POLICY_ID}"

curl -s -X DELETE "https://api.imperva.com/policies/v2/policies/${POLICY_ID}?caid=${CAID}" \
  -H "Accept: application/json" \
  -H "x-API-Id: ${IMPERVA_API_ID}" \
  -H "x-API-Key: ${IMPERVA_API_KEY}" | jq .
