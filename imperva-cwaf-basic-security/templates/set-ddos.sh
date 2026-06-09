#!/bin/bash
# Set DDoS Protection
#
# Credential source: Bitwarden (bws run) — DO NOT hardcode
#   IMPERVA_API_ID, IMPERVA_API_KEY injected by bws run
#
# Identifier source: User env vars — DO NOT hardcode in template
#   SITE_ID, CAID must be set by user before calling
#
# Parameters (pass as env vars):
#   ACTIVATION_MODE   — off | auto | on | adaptive (default: auto)
#   TRAFFIC_THRESHOLD — 10-10000 requests/sec (default: 750)
#   UNKNOWN_CLIENTS_CHALLENGE — none | cookies | javascript | captcha (default: none)
#   BLOCK_NON_ESSENTIAL_BOTS — true | false (default: true)
#
# Usage:
#   SITE_ID=<id> CAID=<caid> ACTIVATION_MODE=auto bws run --project-id <bw_id> -- bash set-ddos.sh
#   SITE_ID=<id> CAID=<caid> ACTIVATION_MODE=adaptive TRAFFIC_THRESHOLD=1500 bws run ... -- bash set-ddos.sh
#   SITE_ID=<id> CAID=<caid> ACTIVATION_MODE=off bws run ... -- bash set-ddos.sh

SITE_ID="${SITE_ID:?Set SITE_ID (from user input or imperva-cwaf-get-site-detail)}"
CAID="${CAID:?Set CAID (from user input or imperva-cwaf-get-site-detail)}"
ACTIVATION_MODE="${ACTIVATION_MODE:-auto}"
TRAFFIC_THRESHOLD="${TRAFFIC_THRESHOLD:-750}"
UNKNOWN_CLIENTS_CHALLENGE="${UNKNOWN_CLIENTS_CHALLENGE:-none}"
BLOCK_NON_ESSENTIAL_BOTS="${BLOCK_NON_ESSENTIAL_BOTS:-true}"

curl -s -X POST "https://my.imperva.com/api/prov/v1/sites/configure/security" \
  -H "Accept: application/json" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -H "x-API-Id: ${IMPERVA_API_ID}" \
  -H "x-API-Key: ${IMPERVA_API_KEY}" \
  --data-urlencode "site_id=${SITE_ID}" \
  --data-urlencode "rule_id=api.threats.ddos" \
  --data-urlencode "activation_mode=api.threats.ddos.activation_mode.${ACTIVATION_MODE}" \
  --data-urlencode "ddos_traffic_threshold=${TRAFFIC_THRESHOLD}" \
  --data-urlencode "unknown_clients_challenge=${UNKNOWN_CLIENTS_CHALLENGE}" \
  --data-urlencode "block_non_essential_bots=${BLOCK_NON_ESSENTIAL_BOTS}" | jq .
