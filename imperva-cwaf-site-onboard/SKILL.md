---
name: imperva-cwaf-site-onboard
description: Onboard a new website to Imperva Cloud WAF using the API
category: imperva-cwaf
version: 2.0.0
---

# Imperva CWAF Site Onboarding

Onboard a new website to Imperva Cloud WAF using the Sites Management API.

## Shared References

| Reference | Description |
|-----------|-------------|
| `../references/skill-dev-standard.md` | Dev standard: template structure, credential rules, known API behaviors, pitfalls |
| `../references/credential-and-identifier-policy.md` | Credential/identifier sourcing rules (Bitwarden bws run) |
| `../references/shell-template-pattern.md` | Shell template patterns (GET→modify→PUT, form-encoded POST, header format) |

## Credential & Identifier Policy (MANDATORY)

| Value | Source | Method |
|-------|--------|--------|
| `IMPERVA_API_ID` | Bitwarden project `hermes-aws` | Only via `bws run --project-id 61c6c700-2d78-4860-b79e-b46200e193e9` |
| `IMPERVA_API_KEY` | Bitwarden project `hermes-aws` | Only via `bws run --project-id 61c6c700-2d78-4860-b79e-b46200e193e9` |
| `CAID` | User / memory | Pass as env var |
| `DOMAIN` | User input | Pass as env var |
| `ORIGIN_IP` | User input | Pass as env var |

**NEVER hardcode credentials or identifiers.**

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

Returns: `siteId`, `name`, `cname`, `siteStatus`

### Step 3: Get CNAME for DNS configuration

```bash
SITE_ID=<id> CAID=<caid> \
  bws run --project-id 61c6c700-2d78-4860-b79e-b46200e193e9 \
  -- bash ~/.hermes/skills/imperva-cwaf/imperva-cwaf-site-onboard/scripts/get-site-cname.sh
```

### Step 4: Update DNS at your provider

Create CNAME record: `<domain> CNAME <cname from step 3>`

### Step 5: Verify

```bash
dig CNAME <domain> +short
```

Site status will be `NOT_CONFIGURED` until DNS propagates.

## Error Handling

| Error | Resolution |
|-------|------------|
| `400 "Name already exists for account"` | Site already onboarded — use get-site-detail instead |
| `401 Unauthorized` | Check Bitwarden credentials |
| `403 Forbidden` | Check Imperva status first |

## Pitfalls
- **Site already exists**: If you get `400 "Name already exists for account"`, the site is already onboarded — just retrieve its CNAME
- **DNS propagation delay**: Site shows `NOT_CONFIGURED` until DNS propagates (minutes to hours)
- **Origin IP**: Get current A record via `dig A <domain> +short` before onboarding

## Related Skills
- `imperva-cwaf-get-site-detail`: Check if site exists / get site ID
- `imperva-cwaf-ssl-management`: Configure SSL/TLS after onboarding
- `imperva-cwaf-policy-management`: Apply policies after onboarding
- `imperva-cwaf-status-check`: Check service status first
