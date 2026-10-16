#!/bin/bash
# Imperva CWAF Policy Management — Add exception to a policy setting
#
# Credential source: Bitwarden (bws run) — DO NOT hardcode
#   IMPERVA_API_ID, IMPERVA_API_KEY injected by bws run
#
# Identifier source: User env vars — DO NOT hardcode in template
#   CAID, POLICY_ID, SETTING_ID must be set by user before calling
#
# Parameters (pass as env vars):
#   SETTING_ID    — the policySettings[].id to add exception to (required)
#   COMMENT       — description for the exception (default: "")
#   EXCEPTIONS    — JSON array of exception objects (required)
#                   e.g. '[{"exceptionType":"IP","values":["10.0.0.0/8"]}]'
#                   For GEO: '[{"exceptionType":"GEO","countries":["TH"],"continents":[]}]'
#
# Usage:
#   CAID=<caid> POLICY_ID=<id> SETTING_ID=<sid> \
#     EXCEPTIONS='[{"exceptionType":"IP","values":["10.0.0.0/8"]}]' \
#     bws run -- bash add-exception.sh

CAID="${CAID:?Set CAID}"
POLICY_ID="${POLICY_ID:?Set POLICY_ID}"
SETTING_ID="${SETTING_ID:?Set SETTING_ID}"
COMMENT="${COMMENT:-}"
EXCEPTIONS="${EXCEPTIONS:?Set EXCEPTIONS}"

curl -s -X POST "https://api.imperva.com/policies/v2/policies/${POLICY_ID}?caid=${CAID}" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -H "x-API-Id: ${IMPERVA_API_ID}" \
  -H "x-API-Key: ${IMPERVA_API_KEY}" \
  -d "{
    \"policySettings\": [
      {
        \"id\": ${SETTING_ID},
        \"policyDataExceptions\": [
          {
            \"comment\": \"${COMMENT}\",
            \"data\": ${EXCEPTIONS}
          }
        ]
      }
    ]
  }" | jq .
