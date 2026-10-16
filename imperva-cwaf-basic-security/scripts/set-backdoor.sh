#!/bin/bash
# Set Backdoor Protection
#
# Credential source: Bitwarden (bws run) — DO NOT hardcode
#   IMPERVA_API_ID, IMPERVA_API_KEY injected by bws run
#
# Identifier source: User env vars — DO NOT hardcode in template
#   SITE_ID, CAID must be set by user before calling
#
# Parameters (pass as env vars):
#   ACTION      — api.threats.action.quarantine_url | api.threats.action.alert | api.threats.action.disabled
#   QUARANTINE_URL — (optional) URL to remove from quarantine
#
# Usage:
#   SITE_ID=<id> CAID=<caid> ACTION=api.threats.action.quarantine_url bws run -- bash set-backdoor.sh
#   SITE_ID=<id> CAID=<caid> ACTION=api.threats.action.alert bws run -- bash set-backdoor.sh
#   SITE_ID=<id> CAID=<caid> ACTION=api.threats.action.disabled bws run -- bash set-backdoor.sh
#   SITE_ID=<id> CAID=<caid> ACTION=api.threats.action.quarantine_url QUARANTINE_URL=/path/to/backdoor.php bws run -- bash set-backdoor.sh

SITE_ID="${SITE_ID:?Set SITE_ID (from user input or imperva-cwaf-get-site-detail)}"
CAID="${CAID:?Set CAID (from user input or imperva-cwaf-get-site-detail)}"
ACTION="${ACTION:?Set ACTION (e.g. api.threats.action.quarantine_url | api.threats.action.alert | api.threats.action.disabled)}"

curl -s -X POST "https://my.imperva.com/api/prov/v1/sites/configure/security" \
  -H "Accept: application/json" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -H "x-API-Id: ${IMPERVA_API_ID}" \
  -H "x-API-Key: ${IMPERVA_API_KEY}" \
  --data-urlencode "site_id=${SITE_ID}" \
  --data-urlencode "rule_id=api.threats.backdoor" \
  --data-urlencode "security_rule_action=${ACTION}" \
  ${QUARANTINE_URL:+--data-urlencode "quarantined_urls=${QUARANTINE_URL}"} | jq .
