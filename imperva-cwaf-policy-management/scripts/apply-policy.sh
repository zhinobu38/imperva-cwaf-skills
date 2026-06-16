#!/bin/bash
# Imperva CWAF Policy Management — Apply policy to a site
#
# Credential source: Bitwarden (bws run) — DO NOT hardcode
#   IMPERVA_API_ID, IMPERVA_API_KEY injected by bws run
#
# Identifier source: User env vars — DO NOT hardcode in template
#   SITE_ID, POLICY_ID must be set by user before calling
#
# Usage:
#   SITE_ID=<id> POLICY_ID=<id> bws run --project-id <bw_id> -- bash apply-policy.sh

SITE_ID="${SITE_ID:?Set SITE_ID}"
POLICY_ID="${POLICY_ID:?Set POLICY_ID}"

curl -s -X POST "https://api.imperva.com/policies/v2/assets/WEBSITE/${SITE_ID}/policies/${POLICY_ID}" \
  -H "Accept: application/json" \
  -H "x-API-Id: ${IMPERVA_API_ID}" \
  -H "x-API-Key: ${IMPERVA_API_KEY}" | jq .
