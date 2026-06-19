#!/bin/bash
# Script to delete an Imperva CWAF site
# Usage: ./delete-site.sh <site_id>
#
# Environment variables (injected by bws run):
#   IMPERVA_API_ID — API ID from Bitwarden
#   IMPERVA_API_KEY — API Key from Bitwarden
#   CAID — Customer Account ID (pass as env var)
#   DRY_RUN — set to "true" to preview without deleting

SITE_ID="${1:?Usage: $0 <site_id>}"
CAID="${CAID:?Set CAID}"
API_ID="${IMPERVA_API_ID:?Set IMPERVA_API_ID}"
API_KEY="${IMPERVA_API_KEY:?Set IMPERVA_API_KEY}"

if [[ "$DRY_RUN" == "true" ]]; then
  echo "[DRY RUN] Would delete site $SITE_ID (CAID: $CAID)"
  echo "  DELETE https://api.imperva.com/sites-mgmt/v3/sites/$SITE_ID?caid=$CAID"
  exit 0
fi

RESPONSE=$(curl -s -w "\n%{http_code}" -X DELETE \
  "https://api.imperva.com/sites-mgmt/v3/sites/${SITE_ID}?caid=${CAID}" \
  -H "Accept: application/json" \
  -H "x-API-Id: $API_ID" \
  -H "x-API-Key: $API_KEY")

HTTP_CODE=$(echo "$RESPONSE" | tail -1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [[ "$HTTP_CODE" == "200" || "$HTTP_CODE" == "204" ]]; then
  echo "✅ Site $SITE_ID deleted successfully (HTTP $HTTP_CODE)"
else
  echo "❌ Failed to delete site $SITE_ID (HTTP $HTTP_CODE)"
  echo "$BODY" | jq . 2>/dev/null || echo "$BODY"
  exit 1
fi
