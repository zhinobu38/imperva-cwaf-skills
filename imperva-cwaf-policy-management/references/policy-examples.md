# Policy Examples

Practical end-to-end examples for common Imperva CWAF policy tasks.
Replace `<caid>`, `<api_id>`, `<api_key>`, `<siteId>` with your values.

---

## 1. Create ACL Policy to Block Countries

### Step 1: Create empty ACL policy
```bash
curl -s -X POST "https://api.imperva.com/policies/v2/policies?caid=<caid>" \
  -H "Accept: application/json" \
  -H "x-API-Id: <api_id>" \
  -H "x-API-Key: <api_key>" \
  -H "Content-Type: application/json" \
  -d '{
    "data": {
      "name": "Block High-Risk Countries",
      "policyType": "ACL",
      "description": "Blocks traffic from high-risk countries",
      "enabled": true
    }
  }' | jq .
```

### Step 2: Note the policy ID from response, then add GEO rule
```bash
curl -s -X POST "https://api.imperva.com/policies/v2/policies/<policyId>?caid=<caid>" \
  -H "Accept: application/json" \
  -H "x-API-Id: <api_id>" \
  -H "x-API-Key: <api_key>" \
  -H "Content-Type: application/json" \
  -d '{
    "data": {
      "policySettings": [
        {
          "policySettingType": "GEO",
          "settingsAction": "BLOCK",
          "data": {
            "geo": {
              "countries": ["RU", "CN", "KP"],
              "continents": []
            }
          }
        }
      ]
    }
  }' | jq .
```

### Step 3: Apply to site
```bash
curl -s -X POST "https://api.imperva.com/policies/v2/assets/WEBSITE/<siteId>/policies/<policyId>?caid=<caid>" \
  -H "Accept: application/json" \
  -H "x-API-Id: <api_id>" \
  -H "x-API-Key: <api_key>" | jq .
```

---

## 2. Create ACL Policy to Block Specific IPs

```bash
# Create policy
curl -s -X POST "https://api.imperva.com/policies/v2/policies?caid=<caid>" \
  -H "x-API-Id: <api_id>" -H "x-API-Key: <api_key>" \
  -H "Content-Type: application/json" \
  -d '{"data":{"name":"Block Malicious IPs","policyType":"ACL","enabled":true}}' | jq .

# Add IP setting (POST to append)
curl -s -X POST "https://api.imperva.com/policies/v2/policies/<policyId>?caid=<caid>" \
  -H "x-API-Id: <api_id>" -H "x-API-Key: <api_key>" \
  -H "Content-Type: application/json" \
  -d '{
    "data": {
      "policySettings": [
        {
          "policySettingType": "IP",
          "settingsAction": "BLOCK",
          "data": {
            "ips": ["198.51.100.0/24", "203.0.113.50"]
          }
        }
      ]
    }
  }' | jq .
```

---

## 3. Create Whitelist Policy for Health Checks

```bash
# Create whitelist policy
curl -s -X POST "https://api.imperva.com/policies/v2/policies?caid=<caid>" \
  -H "x-API-Id: <api_id>" -H "x-API-Key: <api_key>" \
  -H "Content-Type: application/json" \
  -d '{
    "data": {
      "name": "Whitelist Health Checks",
      "policyType": "WHITELIST",
      "description": "Allows health check endpoints to bypass security checks",
      "enabled": true
    }
  }' | jq .

# Add URL whitelist setting
curl -s -X POST "https://api.imperva.com/policies/v2/policies/<policyId>?caid=<caid>" \
  -H "x-API-Id: <api_id>" -H "x-API-Key: <api_key>" \
  -H "Content-Type: application/json" \
  -d '{
    "data": {
      "policySettings": [
        {
          "policySettingType": "URL",
          "settingsAction": "ALLOW",
          "data": {
            "urls": [
              {"pattern": "PREFIX", "url": "/health/"},
              {"pattern": "EQUALS", "url": "/ping"}
            ]
          }
        }
      ]
    }
  }' | jq .
```

---

## 4. Add Exception to Existing Policy

```bash
# First, get the policy with extended=true to see current settings
curl -s -G "https://api.imperva.com/policies/v2/policies/<policyId>?caid=<caid>&extended=true" \
  -H "x-API-Id: <api_id>" -H "x-API-Key: <api_key>" | jq .

# Find the policySettings ID you want to add exception to, then POST
curl -s -X POST "https://api.imperva.com/policies/v2/policies/<policyId>?caid=<caid>" \
  -H "x-API-Id: <api_id>" -H "x-API-Key: <api_key>" \
  -H "Content-Type: application/json" \
  -d '{
    "data": {
      "policySettings": [
        {
          "id": <settingsId>,
          "policyDataExceptions": [
            {
              "comment": "Allow monitoring IP - expires 2026-12-31",
              "data": [
                {
                  "exceptionType": "IP",
                  "values": ["10.0.0.0/8"]
                }
              ]
            }
          ]
        }
      ]
    }
  }' | jq .
```

---

## 5. Create WAF_RULES Policy with SQLi Alert-Only

```bash
# Create the WAF Rules policy
curl -s -X POST "https://api.imperva.com/policies/v2/policies?caid=<caid>" \
  -H "x-API-Id: <api_id>" -H "x-API-Key: <api_key>" \
  -H "Content-Type: application/json" \
  -d '{
    "data": {
      "name": "WAF Alert-Only Mode",
      "policyType": "WAF_RULES",
      "description": "WAF in monitoring/alert-only mode",
      "enabled": true
    }
  }' | jq .

# Set SQL Injection to Alert Only
curl -s -X POST "https://api.imperva.com/policies/v2/policies/<policyId>?caid=<caid>" \
  -H "x-API-Id: <api_id>" -H "x-API-Key: <api_key>" \
  -H "Content-Type: application/json" \
  -d '{
    "data": {
      "policySettings": [
        {
          "policySettingType": "SQL_INJECTION",
          "settingsAction": "ALERT"
        },
        {
          "policySettingType": "CROSS_SITE_SCRIPTING",
          "settingsAction": "ALERT"
        }
      ]
    }
  }' | jq .

# Apply to site (replaces existing WAF policy)
curl -s -X PUT "https://api.imperva.com/policies/v2/assets/WEBSITE/<siteId>/policies/<policyId>?caid=<caid>" \
  -H "x-API-Id: <api_id>" -H "x-API-Key: <api_key>" | jq .
```

---

## 6. Audit All Policies on a Site

```bash
# List all policies applied to a site with full details
curl -s -G "https://api.imperva.com/policies/v2/assets/WEBSITE/<siteId>/policies?caid=<caid>&extended=true" \
  -H "x-API-Id: <api_id>" -H "x-API-Key: <api_key>" | jq .

# Pretty-print specific fields
curl -s -G "https://api.imperva.com/policies/v2/assets/WEBSITE/<siteId>/policies?caid=<caid>&extended=true" \
  -H "x-API-Id: <api_id>" -H "x-API-Key: <api_key>" | jq '
  .value[] | {
    id: .id,
    name: .name,
    type: .policyType,
    enabled: .enabled,
    settings: [.policySettings[] | {type: .policySettingType, action: .settingsAction}]
  }'
```

---

## 7. Remove a Policy from a Site

```bash
curl -s -X DELETE "https://api.imperva.com/policies/v2/assets/WEBSITE/<siteId>/policies/<policyId>?caid=<caid>" \
  -H "Accept: application/json" \
  -H "x-API-Id: <api_id>" \
  -H "x-API-Key: <api_key>" | jq .

# Note: Removing a WAF_RULES policy will re-apply the account default policy.
```

---

## 8. Clone and Modify an Existing Policy

```bash
# Clone
curl -s -X POST "https://api.imperva.com/policies/v2/policies?caid=<caid>&sourcePolicyId=<existingPolicyId>" \
  -H "x-API-Id: <api_id>" -H "x-API-Key: <api_key>" \
  -H "Content-Type: application/json" \
  -d '{}' | jq .

# Modify the cloned policy name
curl -s -X POST "https://api.imperva.com/policies/v2/policies/<newPolicyId>?caid=<caid>" \
  -H "x-API-Id: <api_id>" -H "x-API-Key: <api_key>" \
  -H "Content-Type: application/json" \
  -d '{
    "data": {
      "name": "Cloned and Modified Policy"
    }
  }' | jq .
```
