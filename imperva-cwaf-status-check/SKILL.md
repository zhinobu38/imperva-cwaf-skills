---
name: imperva-cwaf-status-check
description: Check the operational status of Imperva services
category: imperva-cwaf
version: 2.0.0
---

# Imperva CWAF Status Check

Check if Imperva services are operational before making any API calls.
No credentials needed — this is a public status API.

## Response Interpretation

### Normal Operation
```json
{ "indicator": "none", "description": "All Systems Operational", "incidents": 0 }
```

### Incident Indicators
| indicator | Meaning |
|-----------|---------|
| `none` | All systems operational |
| `minor` | Partially degraded service |
| `major` | Major service outage |
| `critical` | Critical service outage |

If indicator is NOT `none`, **STOP** and report to user. Wait for resolution before making API calls.

## Integration with Imperva CWAF API

When encountering ErrorCode 15 ("This request was blocked by our security service"):
1. Run this status check first
2. If incidents reported → wait for resolution
3. If normal → investigate other causes (IP whitelisting, etc.)

## Pitfalls
- A "normal" status doesn't guarantee API accessibility (could be account-specific issues)
- Always combine status checking with direct API testing for complete diagnostics

## Related Skills
- All other imperva-cwaf skills — run this first before any API operations
