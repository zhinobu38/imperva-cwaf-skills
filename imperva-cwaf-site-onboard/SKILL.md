---
name: imperva-cwaf-site-onboard
description: Onboard a new website to Imperva Cloud WAF using the API
category: imperva-cwaf
version: 2.4.0
---

# Imperva CWAF Site Onboarding

Onboard a new website to Imperva Cloud WAF using the Sites Management API v3.

## Shared References

| Reference | Description |
|-----------|-------------|
| `../references/skill-dev-standard.md` | Dev standard: template structure, credential rules, known API behaviors, pitfalls |
| `../references/credential-and-identifier-policy.md` | Credential/identifier sourcing rules (Bitwarden bws run) |
| `../references/shell-template-pattern.md` | Shell template patterns (GET→modify→PUT, form-encoded POST, header format) |
| `references/v3-error-format.md` | v3 API error response format — `{"errors":[...]}` vs legacy `{"res":N}` |

## Credential & Identifier Policy (MANDATORY)

| Value | Source | Method |
|-------|--------|--------|
| `IMPERVA_API_ID` | Bitwarden project `hermes-aws` | Only via `bws run --project-id 61c6c700-2d78-4860-b79e-b46200e193e9` |
| `IMPERVA_API_KEY` | Bitwarden project `hermes-aws` | Only via `bws run --project-id 61c6c700-2d78-4860-b79e-b46200e193e9` |
| `CAID` | User / memory | Pass as env var |
| `DOMAIN` | User input | Pass as env var |
| `ORIGIN_IP` | User input | Pass as env var |
| `SITE_NAME` | User input (optional) | Pass as env var, defaults to DOMAIN |
| `GENERATE_CERT` | User input (optional) | Pass as env var `true|false`, default: true |

**NEVER hardcode credentials or identifiers.**

## API Endpoint

| Operation | Method | Endpoint |
|-----------|--------|----------|
| Onboard site | POST | `https://api.imperva.com/sites-mgmt/v3/sites/onboard?caid=<id>` |
| Get site detail (CNAME) | GET | `https://api.imperva.com/sites-mgmt/v3/sites/<siteId>?caid=<id>` |

## ⚡ MANDATORY: Use the Scripts

**ALWAYS use the provided scripts. Do NOT write inline curl.**

### Step 1: Check if site already exists

Use `imperva-cwaf-get-site-detail` skill first. If site exists, skip to Step 3.

### Step 2: Onboard the site

```bash
CAID=<caid> DOMAIN=<domain> ORIGIN_IP=<ip> \
  bws run --project-id 61c6c700-2d78-4860-b79e-b46200e193e9 \
  -- bash ~/.hermes/skills/imperva-cwaf/imperva-cwaf-site-onboard/scripts/onboard.sh
```

Optional env vars: `SITE_NAME` (default: same as DOMAIN), `GENERATE_CERT` (default: true).

### Step 2.5: Identify Application Type

**🔴 MANDATORY — Never skip this step. Never assume.**

Ask the user: **"What type of application is this site?"**

| Type | Description |
|------|-------------|
| **Web app / Browser-based** | Standard website with HTML pages, forms, user login |
| **API app** | REST/GraphQL API, consumed by mobile apps or SPAs |
| **Static site** | Brochure site, no user-specific content |
| **E-commerce** | Online store with transactions, user accounts |

**Why this matters:**
- **Client Type Restriction** rule differs: web app allows `Browser;FeedFetcher;SearchBot;SiteHelper`, API app needs `User-Agent` filter
- **DDoS challenge**: web app = `javascript`, API app = `none` (with rate limit rule)
- **Cache mode**: static site = `Smart`, web app/API = `Standard`

> ⚠️ **If the user says "both" or "web + API"** — create separate rule sets for different URL patterns (e.g., `/api/*` vs `/*`).

### Step 3: WAF Policy Decision

**🔴 MANDATORY — Never skip this step.**

Ask the user: **"Do you want to use an existing WAF Policy or create a new one for this site?"**

**Option A — Use existing policy:**
1. List policy name + ID for the user to choose (use `imperva-cwaf-policy-management` skill)
2. If the existing policy is already in **Alert (monitoring)** mode → use it as-is
3. If the existing policy is in **Block** mode but the user has false-positive concerns → recommend creating a new policy instead (Option B)

**Option B — Create new policy (recommended in these cases):**
- User has false-positive concerns
- User wants monitoring mode first (Alert for 1-2 weeks → review → switch to Block)
- Existing policy does not match the application type
- Create per best practice: signature categories = **Block** (or **Alert** if false-positive concern)

> 📝 Full best practice: `~/myai/second-brain/20-Cybersecurity/Imperva-CWAF/Best-Practice-Configuration.md`

### Step 4: Apply Security Configuration

**🔴 MANDATORY — Configure based on application type from Step 2.5.**

Use `imperva-cwaf-basic-security` skill for DDoS + bot control, and `imperva-cwaf-custom-rule` skill for reputation + bot rules.

**4a. Reputation Rules (all app types):**
- `Malicious IP Block`: `MaliciousIPList == TorIPs;AnonymousProxyIPs` → Block
- `High Risk IP Block`: `IPReputationRiskLevel == High` → Block

**4b. Bot Management — depends on application type:**

| App Type | Rule Name | Filter | Action |
|----------|-----------|--------|--------|
| **Web app** | Client Type Restriction | `ClientType != Browser;FeedFetcher;SearchBot;SiteHelper` | JS Challenge |
| **API app** | Client Type Restriction | `ClientType != Unknown;HackingTool;FeedFetcher;Browser;SiteHelper & User-Agent not-contains "<UA prefix>"` | JS Challenge |

> ⚠️ **API app**: MUST ask the user for the API client's User-Agent prefix to whitelist.

**4c. DDoS Protection — depends on application type:**

| App Type | Activation Mode | Threshold | Challenge |
|----------|----------------|-----------|-----------|
| **Web app** | `auto` | 1000 (default) | `javascript` |
| **API app** | `auto` | 1000 (default) | `none` |
| **Static site** | `auto` | 1000 (default) | `javascript` |

> ⚠️ **API app with DDoS = none**: Also create a rate limit custom rule to protect against API abuse.

**4d. Form/Login Protection (if applicable):**
- Only if the user confirmed login/form pages exist
- Ask for the login/form URL path
- Create client restriction + rate limit rules

**4e. Data Leakage Prevention:**
- Check origin response headers for `Server`, `X-Powered-By`, etc.
- Create remove response header rules if needed

### Step 5: Get CNAME for DNS configuration

```bash
SITE_ID=<id> CAID=<caid> \
  bws run --project-id 61c6c700-2d78-4860-b79e-b46200e193e9 \
  -- bash ~/.hermes/skills/imperva-cwaf/imperva-cwaf-site-onboard/scripts/get-site-cname.sh
```

Or use `imperva-cwaf-get-site-detail` skill which returns the same info.

### Step 6: Update DNS at your provider

Create CNAME record: `<domain> CNAME <cname from step 5>`

### Step 7: Verify

```bash
dig CNAME <domain> +short
```

Site status will be `NOT_CONFIGURED` until DNS propagates.

## Request / Response Structure

### Onboard Request Body

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `domain` | string | ✅ | FQDN to onboard (e.g. example.com) |
| `name` | string | ✅ | Friendly name (defaults to domain) |
| `servers` | array | ✅ | Origin server IPs |
| `generateCertificate` | boolean | ✅ | Auto-generate SSL cert |
| `type` | string | ✅ | `CLOUD_WAF` |

### Onboard Response — Success (from real API)

> ⚠️ **IMPORTANT**: Response uses nested `site` and `domains` objects — NOT flat fields.

```json
{
  "data": [
    {
      "site": {
        "id": 923531599,
        "name": "example.com",
        "type": "CLOUD_WAF",
        "active": true,
        "accountId": 2429928,
        "creationTime": 1781846565797,
        "cname": "bqotmm7.ng.impervadns.net"
      },
      "domains": [
        {
          "id": 342322972,
          "name": "example.com",
          "protectionStatus": "BYPASSED"
        }
      ],
      "servers": {
        "ips": ["119.110.254.25"]
      },
      "certificateSettings": {
        "validationMethod": "CNAME"
      }
    }
  ]
}
```

**jq paths for success parsing:**
| Output field | jq path |
|-------------|---------|
| siteId | `.data[0].site.id` |
| name | `.data[0].site.name` |
| domain | `.data[0].domains[0].name` |
| cname | `.data[0].site.cname` |
| siteStatus | `.data[0].domains[0].protectionStatus` |
| active | `.data[0].site.active` |

### Onboard Response — Error Formats

**Format 1: Array errors (most common)**
```json
{"errors":[{"status":400,"id":"...","title":"BAD_REQUEST","detail":"Name already exists for account","field":"name"}]}
```

**Format 2: Object error**
```json
{"error":{"status":400,"id":"...","title":"BAD_REQUEST","detail":"Name already exists for account","field":"name"}}
```

**Format 3: WAF block (errorCode 15)**
```json
{"errorCode":"15","description":"This request was blocked by our security service","clientIp":"54.169.152.203","incidentId":"...","hostName":"api.imperva.com"}
```

### Get CNAME Response

Same structure — filters to: `siteId`, `name`, `cname`, `siteStatus`, `active`

## Error Handling

| Code | Meaning | Resolution |
|------|---------|------------|
| 400 `"Name already exists for account"` | Site already onboarded | Use `imperva-cwaf-get-site-detail` instead |
| 401 | Unauthorized | Check Bitwarden credentials (wrong project or expired) |
| 403 / errorCode 15 | WAF intermittent block | Retry with exponential backoff (5s, 15s, 30s, 60s) |
| 403 | Forbidden | Check Imperva service status first |
| 429 | Rate limited | Wait 60s, retry |
| 9415 | Wrong project credentials | Use `hermes-aws` project, not `hermes` |
| 13003 | Adaptive DDoS triggered | Wait and retry with backoff |

## Pitfalls

- **Site already exists**: If you get `400 "Name already exists for account"`, the site is already onboarded — just retrieve its CNAME via `imperva-cwaf-get-site-detail`
- **DNS propagation delay**: Site shows `NOT_CONFIGURED` until DNS propagates (minutes to hours)
- **Origin IP**: Get current A record via `dig A <domain> +short` before onboarding
- **Script response parsing** — The `onboard.sh` script handles 4 response formats: success (`.data`), array errors (`.errors`), object errors (`.error`), and WAF block (`.errorCode`). If you get null fields, the response format may not match any of these — check raw curl output.
- **WAF block (errorCode 15)**: Imperva WAF may intermittently block API requests from cloud/AWS IPs. This is NOT auth failure. Retry with exponential backoff (5s, 15s, 30s, 60s).
- **bws run quoting**: Test scripts through `bws run` for real — special characters get mangled through extra shell layers
- **Response format is nested**: Success response uses `.data[0].site.id` / `.data[0].site.cname` / `.data[0].domains[0].name` — NOT flat `.data[0].id`. The `site` object contains id/name/cname/active, while `domains[0]` contains the domain name and protectionStatus.
- **Error format variants**: API errors come in two formats — `{"errors":[...]}` (array) and `{"error":{...}}` (object). WAF blocks use `{"errorCode":"15",...}` (neither errors nor error field).

## Related Skills

- `imperva-cwaf-get-site-detail`: Check if site exists / get site ID / get CNAME
- `imperva-cwaf-ssl-management`: Configure SSL/TLS after onboarding
- `imperva-cwaf-policy-management`: Apply policies after onboarding
- `imperva-cwaf-basic-security`: DDoS, bot control, security log
- `imperva-cwaf-custom-rule`: Reputation, bot management, form/login rules
- `imperva-cwaf-cache`: Cache mode, response headers
- `imperva-cwaf-status-check`: Check service status first

## Best Practice

> After onboarding, always apply best practice configuration.
> Full details: `~/myai/second-brain/20-Cybersecurity/Imperva-CWAF/Best-Practice-Configuration.md`

**Note:** Best practice content lives in the second-brain only — never duplicate into skill files. Always reference the second-brain.
