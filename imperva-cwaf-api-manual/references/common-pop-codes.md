# Common Imperva PoP Codes

Quick reference for frequently used Imperva Point of Presence codes.

| PoP Code | Location | Region | Notes |
|----------|----------|--------|-------|
| `DMK` | Thailand (Bangkok) | APAC | Primary PoP for Thailand traffic |
| `SIN` | Singapore | APAC | Primary PoP for Singapore / Southeast Asia |

## Usage

Use with the `POP` env var in `imperva-cwaf-troubleshoot` to filter performance statistics:

```bash
# Filter by Thailand PoP
SITE_ID=<id> CAID=<caid> POP=DMK bws run --project-id <bw_id> -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-troubleshoot/scripts/get-performance-stats.sh

# Filter by Singapore PoP
SITE_ID=<id> CAID=<caid> POP=SIN bws run --project-id <bw_id> -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-troubleshoot/scripts/get-performance-stats.sh
```

## Notes

- PoP codes are 3-letter uppercase identifiers
- The `POP` filter is client-side (case-insensitive substring match)
- For the full list of Imperva PoPs, see: https://docs.imperva.com/bundle/cloud-application-security/page/more/pops.htm
