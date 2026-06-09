---
name: imperva-cwaf-policy-management
description: Manage Imperva Cloud WAF policies — WAF rules, ACL, Whitelist, and exceptions. Create, modify, apply, and remove policies across sites.
category: imperva-cwaf
version: 1.1.0
---

# Imperva CWAF Policy Management

Manage security policies (WAF Rules, ACL, Whitelist, File Upload) including policy settings, exceptions, and asset assignments via the Policies API.

## Prerequisites

- API Credentials: CAID, API ID, API Key (same as other Imperva CWAF skills)
- Site ID of the target website (use `imperva-cwaf-get-site-detail` if unknown)

## Shared References

These files are maintained at the `imperva-cwaf/` skill group level and are the
single source of truth for all sub-skills. Do NOT duplicate their content.

| Reference | Description |
|-----------|-------------|
| `../references/skill-dev-standard.md` | Dev standard: template structure, credential rules, known API behaviors, pitfalls |
| `../references/credential-and-identifier-policy.md` | Credential/identifier sourcing rules (Bitwarden bws run) |
| `../references/shell-template-pattern.md` | Shell template patterns (GET→modify→PUT, form-encoded POST, header format) |

## Policy Types

| Policy Type | Description | Apply To |
|-------------|-------------|----------|
| WAF_RULES | WAF rule definitions (SQLi, XSS, etc.) | Websites |
| ACL | Access Control Lists (IP/Geo/URL allow/block) | Websites |
| WHITELIST | Whitelist to skip security checks | Websites |
| FILE_UPLOAD | File upload policies | Websites |

See `references/policy-types.md` for full details on each policy type and their settings.

## API Base URLs

- Policies API v2: `https://api.imperva.com/policies/v2`
- Policies API v3 (account associations): `https://api.imperva.com/policies/v3`

## Authentication Headers

All requests require:
```
x-API-Id: <api_id>
x-API-Key: <api_key>
```
And include `?caid=<caid>` in query string when operating on a different account.

---

## Policy CRUD Operations

### List All Policies

```bash
curl -s -G "https://api.imperva.com/policies/v2/policies?caid=<caid>" \
  -H "Accept: application/json" \
  -H "x-API-Id: <api_id>" \
  -H "x-API-Key: <api_key>"
```

Use `&extended=true` for full policy details including settings.

### Get a Specific Policy

```bash
curl -s -G "https://api.imperva.com/policies/v2/policies/<policyId>?caid=<caid>" \
  -H "Accept: application/json" \
  -H "x-API-Id: <api_id>" \
  -H "x-API-Key: <api_key>"
```

Use `&extended=true` to include full settings and exceptions.

### Create a New Policy

```bash
curl -X POST "https://api.imperva.com/policies/v2/policies?caid=<caid>" \
  -H "Accept: application/json" \
  -H "x-API-Id: <api_id>" \
  -H "x-API-Key: <api_key>" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "My ACL Policy",
    "policyType": "ACL",
    "description": "Blocks traffic from specific countries",
    "enabled": true
  }'
```

Note: The request body is flat JSON — no `data` wrapper needed for create.

### Clone an Existing Policy

```bash
curl -X POST "https://api.imperva.com/policies/v2/policies?caid=<caid>&sourcePolicyId=<sourcePolicyId>" \
  -H "Accept: application/json" \
  -H "x-API-Id: <api_id>" \
  -H "x-API-Key: <api_key>" \
  -H "Content-Type: application/json" \
  -d '{}'
```

### Update Policy (Partial - Append)

POST modifies the policy by appending data (does not overwrite existing settings). Use flat JSON — no `data` wrapper:

```bash
curl -X POST "https://api.imperva.com/policies/v2/policies/<policyId>?caid=<caid>" \
  -H "Accept: application/json" \
  -H "x-API-Id: <api_id>" \
  -H "x-API-Key: <api_key>" \
  -H "Content-Type: application/json" \
  -d '{
    "policySettings": [
      {
        "policySettingType": "GEO",
        "settingsAction": "BLOCK",
        "data": {
          "geo": {
            "countries": ["RU", "CN"],
            "continents": []
          }
        }
      }
    ]
  }'
```

### Overwrite Policy (Full Update)

PUT replaces the entire resource. Omitted fields are removed:

```bash
curl -X PUT "https://api.imperva.com/policies/v2/policies/<policyId>?caid=<caid>" \
  -H "Accept: application/json" \
  -H "x-API-Id: <api_id>" \
  -H "x-API-Key: <api_key>" \
  -H "Content-Type: application/json" \
  -d '<full policy JSON>'
```

**Warning**: PUT is a full overwrite. Always GET the policy first, then modify and PUT the complete JSON.

### Delete a Policy

```bash
curl -X DELETE "https://api.imperva.com/policies/v2/policies/<policyId>?caid=<caid>" \
  -H "Accept: application/json" \
  -H "x-API-Id: <api_id>" \
  -H "x-API-Key: <api_key>"
```

---

## Asset (Site) Assignment

### Apply Policy to a Site

```bash
curl -X POST "https://api.imperva.com/policies/v2/assets/WEBSITE/<siteId>/policies/<policyId>?caid=<caid>" \
  -H "Accept: application/json" \
  -H "x-API-Id: <api_id>" \
  -H "x-API-Key: <api_key>"
```

### Remove Policy from a Site

```bash
curl -X DELETE "https://api.imperva.com/policies/v2/assets/WEBSITE/<siteId>/policies/<policyId>?caid=<caid>" \
  -H "Accept: application/json" \
  -H "x-API-Id: <api_id>" \
  -H "x-API-Key: <api_key>"
```

### List All Policies Applied to a Site

```bash
curl -s -G "https://api.imperva.com/policies/v2/assets/WEBSITE/<siteId>/policies?caid=<caid>" \
  -H "Accept: application/json" \
  -H "x-API-Id: <api_id>" \
  -H "x-API-Key: <api_key>"
```

### Check if a Policy is Applied to a Site

```bash
curl -s -G "https://api.imperva.com/policies/v2/policies/<policyId>/assets/WEBSITE/<siteId>?caid=<caid>" \
  -H "Accept: application/json" \
  -H "x-API-Id: <api_id>" \
  -H "x-API-Key: <api_key>"
```

### Replace All Policies on a Site (WAF Rules Only)

PUT replaces all existing policies with the specified one:

```bash
curl -X PUT "https://api.imperva.com/policies/v2/assets/WEBSITE/<siteId>/policies/<policyId>?caid=<caid>" \
  -H "Accept: application/json" \
  -H "x-API-Id: <api_id>" \
  -H "x-API-Key: <api_key>"
```

---

## Account-Level Operations

### List Available and Default Policies

```bash
curl -s -G "https://api.imperva.com/policies/v3/accounts/associated-policies?caid=<caid>" \
  -H "Accept: application/json" \
  -H "x-API-Id: <api_id>" \
  -H "x-API-Key: <api_key>"
```

### Update Account Default Policies

Use PATCH for partial update or PUT for full overwrite of account policy associations.

---

## Policy Settings Reference

Settings define the policy rules within a policy. Each setting has:

- **policySettingType**: GEO, IP, URL, HEADER_VALUE, or WAF-related types (CROSS_SITE_SCRIPTING, SQL_INJECTION, etc.)
- **settingsAction**: BLOCK, ALLOW, ALERT, BLOCK_USER, BLOCK_IP, IGNORE, HIDDEN_ALERT, MASK
- **data**: Type-specific data (see examples below)

### GEO Setting

```json
{
  "policySettingType": "GEO",
  "settingsAction": "BLOCK",
  "data": {
    "geo": {
      "countries": ["RU", "CN", "KP"],
      "continents": ["AS"]
    }
  }
}
```

### IP Setting

```json
{
  "policySettingType": "IP",
  "settingsAction": "BLOCK",
  "data": {
    "ips": ["192.168.1.0/24", "10.0.0.5"]
  }
}
```

### URL Setting

```json
{
  "policySettingType": "URL",
  "settingsAction": "ALLOW",
  "data": {
    "urls": [
      {
        "pattern": "CONTAINS",
        "url": "/api/health"
      },
      {
        "pattern": "PREFIX",
        "url": "/public/"
      }
    ]
  }
}
```

### WAF Rule Override Setting

```json
{
  "policySettingType": "SQL_INJECTION",
  "settingsAction": "ALERT"
}
```

Available WAF policy setting types: CROSS_SITE_SCRIPTING, ILLEGAL_RESOURCE_ACCESS, REMOTE_FILE_INCLUSION, SQL_INJECTION, RESP_DATA_LEAK, MALICIOUS_FILE_UPLOAD.

---

## Exceptions

Exceptions override policy settings for specific conditions. Exception types include: GEO, IP, URL, URL_NOT_EQUALS, URL_NOT_CONTAINS, URL_PREFIX, URL_SUFFIX, URL_NOT_PREFIX, URL_NOT_SUFFIX, URL_CONTAINS, CLIENT_ID, SITE_ID, HTTP_PARAM, USER_AGENT, FILE_HASH.

### Add Exception to a Policy Setting

Add exception via POST (append — no `data` wrapper):

```bash
curl -X POST "https://api.imperva.com/policies/v2/policies/<policyId>?caid=<caid>" \
  -H "Accept: application/json" \
  -H "x-API-Id: <api_id>" \
  -H "x-API-Key: <api_key>" \
  -H "Content-Type: application/json" \
  -d '{
    "policySettings": [
      {
        "id": <settingsId>,
        "policyDataExceptions": [
          {
            "comment": "Allow pen test IP",
            "data": [
              {
                "exceptionType": "IP",
                "values": ["203.0.113.0/24"]
              }
            ]
          }
        ]
      }
    ]
  }'
```

### Exception with GEO Type

```json
{
  "data": [
    {
      "exceptionType": "GEO",
      "countries": ["TH", "US"],
      "continents": []
    }
  ]
}
```

### Exception with URL Type

```json
{
  "data": [
    {
      "exceptionType": "URL_CONTAINS",
      "values": ["/api/v1/healthcheck", "/status"]
    }
  ]
}
```

### Exception with USER_AGENT Type

```json
{
  "data": [
    {
      "exceptionType": "USER_AGENT",
      "values": ["GoogleBot", "BingBot"]
    }
  ]
}
```

---

## Action Values Reference

### Settings Actions

| Action | Description |
|--------|-------------|
| BLOCK | Block the request |
| ALLOW | Allow the request (skip checks) |
| ALERT | Log but don't block |
| BLOCK_USER | Block the user session |
| BLOCK_IP | Block the IP address |
| IGNORE | Skip this policy rule entirely |
| HIDDEN_ALERT | Log internally without alerting |
| MASK | Mask sensitive data |

### Exception Types

| Type | Values Format | Example |
|------|---------------|---------|
| GEO | Country/continent codes | TH, US, APAC |
| IP | IP addresses/CIDRs | 192.168.1.0/24 |
| URL | URL strings | /admin/login |
| URL_PREFIX | URL prefix string | /api/ |
| URL_SUFFIX | URL suffix string | .php |
| URL_CONTAINS | URL substring | login |
| USER_AGENT | User agent strings | GoogleBot |

---

## Common Workflows

### Create an ACL Policy and Apply to Site

1. Create the policy:
   ```bash
   curl -X POST "https://api.imperva.com/policies/v2/policies?caid=<caid>" \
     -H "x-API-Id: <api_id>" -H "x-API-Key: <api_key>" \
     -H "Content-Type: application/json" \
     -d '{"name":"Block RU Traffic","policyType":"ACL","enabled":true}'
   ```

2. Note the returned policy ID.

3. Add GEO setting to the policy:
   ```bash
   curl -X POST "https://api.imperva.com/policies/v2/policies/<policyId>?caid=<caid>" \
     -H "x-API-Id: <api_id>" -H "x-API-Key: <api_key>" \
     -H "Content-Type: application/json" \
     -d '{"policySettings":[{"policySettingType":"GEO","settingsAction":"BLOCK","data":{"geo":{"countries":["RU"]}}}]}'
   ```

4. Apply the policy to the site:
   ```bash
   curl -X POST "https://api.imperva.com/policies/v2/assets/WEBSITE/<siteId>/policies/<policyId>?caid=<caid>" \
     -H "x-API-Id: <api_id>" -H "x-API-Key: <api_key>"
   ```

### Add Whitelist Exception for Health Check URLs

1. Get existing whitelist policy for the site:
   ```bash
   curl -s -G "https://api.imperva.com/policies/v2/assets/WEBSITE/<siteId>/policies?caid=<caid>&extended=true" \
     -H "x-API-Id: <api_id>" -H "x-API-Key: <api_key>" | jq '.value[] | select(.policyType=="WHITELIST")'
   ```

2. Add exception to the whitelist policy settings.

### Copy Policy from One Site to Another

1. Get the source policy details (extended=true).
2. Create a new policy with `?sourcePolicyId=<sourceId>`.
3. Apply the new policy to the target site.

---

## Response Format

All responses follow this envelope:
```json
{
  "isError": false,
  "value": { ... }
}
```

When `isError` is `true`, `value` contains an error message string.

---

## Error Handling

| HTTP Code | Meaning |
|-----------|---------|
| 200 | Success |
| 400 | Bad Request (invalid JSON, missing fields, invalid policy type) |
| 401 | Unauthorized (invalid API credentials) |
| 404 | Not Found (policy or site doesn't exist) |
| 429 | Rate Limited |
| 500 | Internal Server Error |

---

## Tips

- Always use `GET` with `extended=true` before modifying a policy to understand current state.
- POST to `/policies/<id>` appends data; PUT replaces entirely. Use POST to add settings, PUT to fully reconstruct.
- When removing exceptions via PUT, include all settings without the exception you want to remove.
- Asset type is `WEBSITE` for all site-level policy assignments.
- The v3 API is used for account-level policy associations only.
- WAF_RULES policies cannot be disabled once created.

## Pitfalls

- **No `data` wrapper in ANY Imperva API request body.** All Imperva Cloud WAF APIs (Policies, Custom Rules, Cache, etc.) use flat JSON for POST/PUT bodies — do NOT wrap in `{"data": {...}}` anywhere.
- **Always remove policy from site before deleting.** If you DELETE a policy that is still applied to a site, the API may return an error. Unassign first, then delete.
- **Exception settings must reference the parent setting `id`.** When adding an exception via POST, you must include the `id` of the existing `policySettings` entry. GET the policy first to find it.
- **Response `isError` is a boolean field**, not an HTTP status code. Check `isError` in the JSON body, not just HTTP status.

## Verified Response Examples

Create policy response:
```json
{
  "value": {
    "id": 2100174,
    "name": "My Policy",
    "description": "...",
    "enabled": true,
    "accountId": 700477,
    "policyType": "ACL",
    "lastModified": "Jun 2, 2026, 3:10:02 PM",
    "lastModifiedBy": 2808936,
    "blockRoute": true,
    "defaultPolicyConfig": [],
    "policySettings": []
  },
  "isError": false
}
```

GEO setting response (after POST):
```json
{
  "value": {
    "id": 2100174,
    "policySettings": [{
      "id": 9467106,
      "policyId": 2100174,
      "settingsAction": "BLOCK",
      "policySettingType": "GEO",
      "data": {
        "headerValue": null,
        "geo": { "countries": ["RU"], "continents": [] },
        "ips": null,
        "urls": null
      },
      "policyDataExceptions": []
    }]
  },
  "isError": false
}
```

Apply to site response:
```json
{
  "value": [{
    "id": 4539316,
    "policyId": 2100174,
    "assetId": <EXAMPLE_SITE_ID>,
    "assetType": "WEBSITE"
  }],
  "isError": false
}
```

Delete policy response:
```json
{
  "value": "Deleted successfully",
  "isError": false
}
```

## Related Skills

- `imperva-cwaf-api-manual`: Full API specification reference in `api-spec/policies-api.yaml`
- `imperva-cwaf-custom-rule`: Manage custom rules (separate from policies)
- `imperva-cwaf-get-site-detail`: Get site IDs and current configuration
