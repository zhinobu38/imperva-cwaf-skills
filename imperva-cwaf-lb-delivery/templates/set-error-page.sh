#!/bin/bash
# Set Custom Error Page
#
# Credential source: Bitwarden (bws run) — DO NOT hardcode
#   IMPERVA_API_ID, IMPERVA_API_KEY injected by bws run
#
# Identifier source: User env vars — DO NOT hardcode in template
#   SITE_ID, CAID must be set by user before calling
#
# Usage:
#   SITE_ID=<id> CAID=<caid> ERROR_TYPE=access_denied ERROR_HTML='<html>...' bws run --project-id <id> -- bash set-error-page.sh
#   SITE_ID=<id> CAID=<caid> ERROR_TYPE=access_denied ERROR_HTML='' bws run --project-id <id> -- bash set-error-page.sh

SITE_ID="${SITE_ID:?Set SITE_ID (from user input or imperva-cwaf-get-site-detail)}"
CAID="${CAID:?Set CAID (from user input or imperva-cwaf-get-site-detail)}"
ERROR_TYPE="${ERROR_TYPE:?Set ERROR_TYPE (e.g., access_denied)}"
ERROR_HTML="${ERROR_HTML:-}"

KEY="error.type.${ERROR_TYPE}"

# 1. GET current full delivery settings
FULL=$(curl -s -X GET "https://my.imperva.com/api/prov/v2/sites/${SITE_ID}/settings/delivery?caid=${CAID}" \
  -H "Accept: application/json" \
  -H "x-API-Id: ${IMPERVA_API_ID}" \
  -H "x-API-Key: ${IMPERVA_API_KEY}")

# 2. Merge custom error page into full settings
# Remove read-only port fields before PUT
PAYLOAD=$(echo "${FULL}" | jq --arg key "${KEY}" --arg html "${ERROR_HTML}" '
  .custom_error_page.custom_error_page_templates[$key] = $html
  | del(.network.port)
  | del(.network.ssl_port)
')

# 3. PUT full delivery settings
curl -s -X PUT "https://my.imperva.com/api/prov/v2/sites/${SITE_ID}/settings/delivery?caid=${CAID}" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -H "x-API-Id: ${IMPERVA_API_ID}" \
  -H "x-API-Key: ${IMPERVA_API_KEY}" \
  -d "${PAYLOAD}" | jq .
