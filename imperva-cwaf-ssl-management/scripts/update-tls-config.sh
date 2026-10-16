#!/bin/bash
# Update TLS/HSTS Configuration (PATCH)
#
# Credential source: Bitwarden (bws run) — DO NOT hardcode
#   IMPERVA_API_ID, IMPERVA_API_KEY injected by bws run
#
# Identifier source: User env vars — DO NOT hardcode in script
#   SITE_ID, CAID must be set by user before calling
#
# Parameters (pass as env vars):
#   TLS_PROFILE          — DEFAULT | CUSTOM | ENHANCED_SECURITY (default: ENHANCED_SECURITY)
#   HSTS_ENABLED         — true | false (default: true)
#   HSTS_MAX_AGE         — seconds (default: 31536000)
#   HSTS_SUBDOMAINS      — true | false (default: false)
#   HSTS_PRELOADED       — true | false (default: false)
#   DISABLE_PQC_SUPPORT  — true | false (default: false)
#
# Usage:
#   SITE_ID=<id> CAID=<caid> bws run -- bash update-tls-config.sh
#   SITE_ID=<id> CAID=<caid> TLS_PROFILE=DEFAULT HSTS_ENABLED=false bws run ... -- bash update-tls-config.sh

SITE_ID="${SITE_ID:?Set SITE_ID}"
CAID="${CAID:?Set CAID}"
TLS_PROFILE="${TLS_PROFILE:-ENHANCED_SECURITY}"
HSTS_ENABLED="${HSTS_ENABLED:-true}"
HSTS_MAX_AGE="${HSTS_MAX_AGE:-31536000}"
HSTS_SUBDOMAINS="${HSTS_SUBDOMAINS:-false}"
HSTS_PRELOADED="${HSTS_PRELOADED:-false}"
DISABLE_PQC_SUPPORT="${DISABLE_PQC_SUPPORT:-false}"

curl -s -X PATCH "https://api.imperva.com/sites-mgmt/v3/sites/${SITE_ID}/settings/TLSConfiguration?caid=${CAID}" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -H "x-API-Id: ${IMPERVA_API_ID}" \
  -H "x-API-Key: ${IMPERVA_API_KEY}" \
  -d "{
    \"data\": [{
      \"hstsConfiguration\": {
        \"isEnabled\": ${HSTS_ENABLED},
        \"maxAge\": ${HSTS_MAX_AGE},
        \"subDomainsIncluded\": ${HSTS_SUBDOMAINS},
        \"preLoaded\": ${HSTS_PRELOADED}
      },
      \"inboundTlsSettings\": {
        \"configurationProfile\": \"${TLS_PROFILE}\"
      },
      \"disablePQCSupport\": ${DISABLE_PQC_SUPPORT}
    }]
  }" | jq .
