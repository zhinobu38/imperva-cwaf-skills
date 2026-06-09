#!/bin/bash
# Set Bot Access Control (v1 - block/challenge)
#
# Credential source: Bitwarden (bws run) — DO NOT hardcode
#   IMPERVA_API_ID, IMPERVA_API_KEY injected by bws run
#
# Identifier source: User env vars — DO NOT hardcode in template
#   SITE_ID, CAID must be set by user before calling
#
# Parameters (pass as env vars):
#   BLOCK_BAD_BOTS          — true | false (default: true)
#   CHALLENGE_SUSPECTED_BOTS — true | false (default: true)
#
# Usage:
#   SITE_ID=<id> CAID=<caid> BLOCK_BAD_BOTS=true CHALLENGE_SUSPECTED_BOTS=true bws run --project-id <bw_id> -- bash set-bot-control.sh
#   SITE_ID=<id> CAID=<caid> BLOCK_BAD_BOTS=false bws run ... -- bash set-bot-control.sh

SITE_ID="${SITE_ID:?Set SITE_ID (from user input or imperva-cwaf-get-site-detail)}"
CAID="${CAID:?Set CAID (from user input or imperva-cwaf-get-site-detail)}"
BLOCK_BAD_BOTS="${BLOCK_BAD_BOTS:-true}"
CHALLENGE_SUSPECTED_BOTS="${CHALLENGE_SUSPECTED_BOTS:-true}"

curl -s -X POST "https://my.imperva.com/api/prov/v1/sites/configure/security" \
  -H "Accept: application/json" \
  -H "Content-Type: application/x-www-form-urlencoded"  \
  -H "x-API-Id: ${IMPERVA_API_ID}" \
  -H "x-API-Key: ${IMPERVA_API_KEY}" \
  --data-urlencode "site_id=${SITE_ID}" \
  --data-urlencode "rule_id=api.threats.bot_access_control" \
  --data-urlencode "block_bad_bots=${BLOCK_BAD_BOTS}" \
  --data-urlencode "challenge_suspected_bots=${CHALLENGE_SUSPECTED_BOTS}" | jq .
