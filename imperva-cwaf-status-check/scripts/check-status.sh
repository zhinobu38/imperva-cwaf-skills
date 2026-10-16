#!/bin/bash
# Imperva CWAF — Check Service Status
# Usage: bws run -- bash check-status.sh
# No credentials needed — public status API

curl -s https://status.imperva.com/api/v2/summary.json | jq '{
  indicator: .status.indicator,
  description: .status.description,
  incidents: (.incidents | length),
  components: [.components[] | select(.status != "operational") | {name: .name, status: .status}]
}'
