#!/bin/bash
# imperva-visits.sh — Wrapper for imperva_get_stats.py visits with proper arg handling
# Usage: SITE_ID=<id> CAID=<caid> bws run --project-id <id> -- bash imperva-visits.sh [args]

cd "$(dirname "$0")"
SITE_ID="${SITE_ID}" CAID="${CAID}" python3 scripts/imperva_get_stats.py visits "$@"
