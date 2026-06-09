---
name: imperva-cwaf-status-check
description: Check the operational status of Imperva services
category: imperva-cwaf
version: 1.0.0
---

# Imperva CWAF Status Check

This skill provides functionality to check the operational status of Imperva services using their public status API.

## Shared References

These files are maintained at the `imperva-cwaf/` skill group level and are the
single source of truth for all sub-skills. Do NOT duplicate their content.

| Reference | Description |
|-----------|-------------|
| `../references/skill-dev-standard.md` | Dev standard: template structure, credential rules, known API behaviors, pitfalls |
| `../references/credential-and-identifier-policy.md` | Credential/identifier sourcing rules (Bitwarden bws run) |
| `../references/shell-template-pattern.md` | Shell template patterns (GET→modify→PUT, form-encoded POST, header format) |

## Status Endpoint
```
GET https://status.imperva.com/api/v2/summary.json
```

## Purpose
Check if Imperva services are operational and identify any ongoing incidents that might affect API accessibility.

## Usage

### Via Command Line
```bash
curl --silent --show-error https://status.imperva.com/api/v2/summary.json
```

### Via Hermes Agent
```bash
# Using the skill's functionality
hermes run imperva-cwaf-status-check
```

## Response Interpretation

### Normal Operation
- HTTP 200 OK
- JSON response with "status.indicator": "none" and "status.description": "All Systems Operational"

### Incident Indicators
- HTTP 200 OK but JSON shows incidents/maintenance
- Check status.indicator field:
  - none: All systems operational
  - minor: Partially degraded service
  - major: Major service outage
  - critical: Critical service outage
- Check components array for specific service statuses:
  - operational: Service working normally
  - degraded_performance: Service experiencing reduced performance
  - partial_outage: Service partially unavailable
  - major_outage: Major service outage
  - under_maintenance: Service undergoing maintenance

## Error Handling
- Network connectivity issues: Check your internet connection
- DNS resolution failures: Verify status.imperva.com resolves correctly
- HTTP errors (other than 200): May indicate temporary service issues
- JSON parsing errors: Response may not be valid JSON

## Integration with Imperva CWAF API
When encountering ErrorCode 15 from Imperva CWAF API ("This request was blocked by our security service"):
1. First check Imperva status using this skill
2. If status shows incidents (status.indicator is minor, major, or critical), wait for resolution before retrying API calls
3. If status shows normal operation (status.indicator is none), investigate other causes (IP whitelisting, mTLS requirements, etc.)

## Example Output Analysis

### Normal Operation Indicator
```json
{
  "status": {
    "indicator": "none",
    "description": "All Systems Operational"
  }
}
```

### Incident Indicator
```json
{
  "status": {
    "indicator": "minor",
    "description": "Partially Degraded Service"
  },
  "components": [
    {
      "id": "7sjdbd6hh2sx",
      "name": "New York 2, NY (EWR)",
      "status": "degraded_performance"
    }
  ]
}
```

## Notes
- This skill checks Imperva's public status API, not the HTML status page directly
- A "normal" status doesn't guarantee API accessibility (could be account-specific issues)
- Always combine status checking with direct API testing for complete diagnostics
- Part of the imperva-cwaf skill set for Imperva Cloud WAF API interactions