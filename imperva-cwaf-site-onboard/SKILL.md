---
name: imperva-cwaf-site-onboard
description: Onboard a new website to Imperva Cloud WAF using the API
category: imperva-cwaf
version: 2.1.0
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

### Step 3: Get CNAME for DNS configuration

```bash
SITE_ID=<id> CAID=<caid> \
  bws run --project-id 61c6c700-2d78-4860-b79e-b46200e193e9 \
  -- bash ~/.hermes/skills/imperva-cwaf/imperva-cwaf-site-onboard/scripts/get-site-cname.sh
```

Or use `imperva-cwaf-get-site-detail` skill which returns the same info.

### Step 4: Update DNS at your provider

Create CNAME record: `<domain> CNAME <cname from step 3>`

### Step 5: Verify

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

### Onboard Response (from real API)

```json
{
  "data": [
    {
      "id": 123456789,
      "name": "example.com",
      "domain": "example.com",
      "cname": "xyz123.ksf.ms",
      "siteStatus": "NOT_CONFIGURED",
      "active": true,
      "type": "CLOUD_WAF",
      "creationTime": "2026-06-17T12:00:00Z"
    }
  ]
}
```

Output fields: `siteId`, `name`, `domain`, `cname`, `siteStatus`, `active`

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
- **WAF block (errorCode 15)**: Imperva WAF may intermittently block API requests from cloud/AWS IPs. This is NOT auth failure. Retry with exponential backoff (5s, 15s, 30s, 60s).
- **bws run quoting**: Test scripts through `bws run` for real — special characters get mangled through extra shell layers
- **`.data[0]` response format**: v3 onboard API returns array in `.data[]`. Script extracts first element. If API changes to single object, update jq filter.

## Related Skills

- `imperva-cwaf-get-site-detail`: Check if site exists / get site ID / get CNAME
- `imperva-cwaf-ssl-management`: Configure SSL/TLS after onboarding
- `imperva-cwaf-policy-management`: Apply policies after onboarding
- `imperva-cwaf-status-check`: Check service status first
