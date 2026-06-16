#!/bin/bash
# Update Redirection Settings
#
# Credential source: Bitwarden (bws run) — DO NOT hardcode
#   IMPERVA_API_ID, IMPERVA_API_KEY injected by bws run
#
# Identifier source: User env vars — DO NOT hardcode in template
#   SITE_ID, CAID must be set by user before calling
#
# Usage:
#   SITE_ID=<id> CAID=<caid> REDIRECT_HTTP_TO_HTTPS=true bws run --project-id <id> -- bash update-redirection.sh
#   SITE_ID=<id> CAID=<caid> REDIRECT_NAKED_TO_FULL=true bws run ... -- bash update-redirection.sh

SITE_ID="${SITE_ID:?Set SITE_ID (from user input or imperva-cwaf-get-site-detail)}"
CAID="${CAID:?Set CAID (from user input or imperva-cwaf-get-site-detail)}"

# Defaults (only include in payload if env vars are set)
REDIRECT_NAKED_TO_FULL="${REDIRECT_NAKED_TO_FULL:-}"
REDIRECT_HTTP_TO_HTTPS="${REDIRECT_HTTP_TO_HTTPS:-}"

# Build redirection JSON using jq — only include set fields
REDIRECTION=$(jq -n \
  --arg rnf "${REDIRECT_NAKED_TO_FULL}" \
  --arg rhs "${REDIRECT_HTTP_TO_HTTPS}" \
  '{
    redirection: (
      {}
      | if ($rnf != "") then .redirect_naked_to_full = ($rnf == "true") else . end
      | if ($rhs != "") then .redirect_http_to_https = ($rhs == "true") else . end
    )
  }')

echo "Redirection update: ${REDIRECTION}"

# PUT partial update
curl -s -X PUT "https://my.imperva.com/api/prov/v2/sites/${SITE_ID}/settings/delivery?caid=${CAID}" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -H "x-API-Id: ${IMPERVA_API_ID}" \
  -H "x-API-Key: ${IMPERVA_API_KEY}" \
  -d "${REDIRECTION}" | jq .
