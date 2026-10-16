#!/bin/bash
# Imperva CWAF — List custom rules for a site
#
# Credential source: Bitwarden (bws run) — DO NOT hardcode
#   IMPERVA_API_ID, IMPERVA_API_KEY injected by bws run
#
# Identifier source: User env vars — DO NOT hardcode in template
#   CAID, SITE_ID must be set by user before calling
#
# Optional filters (pass as env vars):
#   FILTER_NAME    — filter by rule name (substring match, case-insensitive)
#   FILTER_ACTION  — filter by action (e.g. RULE_ACTION_BLOCK)
#   FILTER_ENABLED — filter by status: true | false
#
# Output format (pass as env var):
#   OUTPUT_FORMAT — json (default) | table
#
# Usage:
#   CAID=<caid> SITE_ID=<id> bws run -- bash list-rules.sh
#   CAID=<caid> SITE_ID=<id> FILTER_ACTION=RULE_ACTION_BLOCK OUTPUT_FORMAT=table bws run -- bash list-rules.sh

CAID="${CAID:?Set CAID}"
SITE_ID="${SITE_ID:?Set SITE_ID}"
OUTPUT_FORMAT="${OUTPUT_FORMAT:-json}"

RESPONSE=$(curl -s -G "https://my.imperva.com/api/prov/v3/rules?caid=${CAID}&siteIds=${SITE_ID}" \
  -H "Accept: application/json" \
  -H "x-API-Id: ${IMPERVA_API_ID}" \
  -H "x-API-Key: ${IMPERVA_API_KEY}")

# Apply filters using jq
FILTERED=$(echo "$RESPONSE" | jq --arg name "${FILTER_NAME:-}" --arg action "${FILTER_ACTION:-}" --arg enabled "${FILTER_ENABLED:-}" '
  .data |= map(select(
    ($name == "" or (.rule.name | test($name; "i"))) and
    ($action == "" or .rule.action == $action) and
    ($enabled == "" or (.rule.enabled | tostring) == $enabled)
  ))
')

if [ "$OUTPUT_FORMAT" = "table" ]; then
  echo "$FILTERED" | jq -r '
    .data[] |
    [.rule.rule_id, .rule.name, .rule.action, (.rule.enabled | tostring), .rule.filter] |
    @tsv
  ' | awk -F'\t' 'BEGIN {
    printf "%-12s %-35s %-30s %-10s %s\n", "RULE_ID", "NAME", "ACTION", "ENABLED", "FILTER"
    printf "%-12s %-35s %-30s %-10s %s\n", "--------", "----", "------", "-------", "------"
  }
  {
    printf "%-12s %-35s %-30s %-10s %s\n", $1, $2, $3, $4, $5
  }'
else
  echo "$FILTERED" | jq .
fi
