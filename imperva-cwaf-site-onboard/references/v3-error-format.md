# Imperva CWAF v3 API Error Response Format

v3 endpoints (sites-mgmt/v3) use a different error format than legacy v1/v2.

## Error Response Shape

```json
{
  "errors": [
    {
      "status": 400,
      "id": "ceccb22300000000e1f79d9112cbe0ed",
      "source": {
        "pointer": "/v3/sites/onboard"
      },
      "title": "BAD_REQUEST",
      "detail": "Name already exists for account",
      "field": "name"
    }
  ]
}
```

## Key Differences from Legacy

| Aspect | v1/v2 (legacy) | v3 (current) |
|--------|----------------|--------------|
| Error envelope | {"res": N, "description": "..."} | {"errors": [{"status": N, "detail": "..."}]} |
| Success data | {"sites": [...]} or {"data": ...} | {"data": [...]} |
| Error code field | res (numeric) | errors[0].status (HTTP status) |
| Error message | description | errors[0].detail |

## Script Pattern for v3

Always check for .errors before .data:

```bash
RESPONSE=$(curl -s -X POST ...)

if echo "${RESPONSE}" | jq -e '.errors' > /dev/null 2>&1; then
  echo "${RESPONSE}" | jq '{error: .errors[0]}'
else
  echo "${RESPONSE}" | jq '.data[0]'
fi
```

## Known v3 Error Cases

| Status | Detail | Resolution |
|--------|--------|------------|
| 400 | "Name already exists for account" | Site already onboarded - use get-site-detail |
| 401 | Unauthorized | Check Bitwarden credentials |
| 403 | WAF block (errorCode 15) | Retry with exponential backoff |
| 429 | Rate limited | Wait 60s, retry |
