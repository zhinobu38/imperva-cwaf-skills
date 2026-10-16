#!/bin/bash
# Imperva CWAF Policy Management — List all policies
#
# Credential source: Bitwarden (bws run) — DO NOT hardcode
#   IMPERVA_API_ID, IMPERVA_API_KEY injected by bws run
#
# Identifier source: User env vars — DO NOT hardcode in template
#   CAID must be set by user before calling
#
# Parameters (pass as env vars):
#   EXTENDED — true | false (default: true, for full policy details)
#   POLICY_TYPE — WAF_RULES | ACL | WHITELIST | FILE_UPLOAD (optional filter)
#
# Usage:
#   CAID=<caid> bws run -- bash list-policies.sh
#   CAID=<caid> POLICY_TYPE=ACL bws run -- bash list-policies.sh

CAID="${CAID:?Set CAID}"
EXTENDED="${EXTENDED:-true}"

ARGS="caid=${CAID}&extended=${EXTENDED}"
if [ -n "${POLICY_TYPE}" ]; then
  ARGS="${ARGS}&policyType=${POLICY_TYPE}"
fi

curl -s -G "https://api.imperva.com/policies/v2/policies?${ARGS}" \
  -H "Accept: application/json" \
  -H "x-API-Id: ${IMPERVA_API_ID}" \
  -H "x-API-Key: ${IMPERVA_API_KEY}" | jq .
