#!/bin/bash
# Imperva CWAF Policy Management — Add IP setting to a policy
#
# Credential source: Bitwarden (bws run) — DO NOT hardcode
#   IMPERVA_API_ID, IMPERVA_API_KEY injected by bws run
#
# Identifier source: User env vars — DO NOT hardcode in template
#   CAID, POLICY_ID must be set by user before calling
#
# Parameters (pass as env vars):
#   IPS      — JSON array of IPs/CIDRs (e.g. '["198.51.100.0/24","10.0.0.1"]')
#   ACTION   — BLOCK | ALLOW | ALERT (default: BLOCK)
#
# Usage:
#   CAID=<caid> POLICY_ID=<id> IPS='["198.51.100.0/24"]' ACTION=BLOCK \
#     bws run -- bash add-ip-setting.sh

CAID="${CAID:?Set CAID}"
POLICY_ID="${POLICY_ID:?Set POLICY_ID}"
IPS="${IPS:-[]}"
ACTION="${ACTION:-BLOCK}"

curl -s -X POST "https://api.imperva.com/policies/v2/policies/${POLICY_ID}?caid=${CAID}" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -H "x-API-Id: ${IMPERVA_API_ID}" \
  -H "x-API-Key: ${IMPERVA_API_KEY}" \
  -d "{
    \"policySettings\": [{
      \"policySettingType\": \"IP\",
      \"settingsAction\": \"${ACTION}\",
      \"data\": {
        \"ips\": ${IPS}
      }
    }]
  }" | jq .
