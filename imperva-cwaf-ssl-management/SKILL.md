---
name: imperva-cwaf-ssl-management
description: Manage SSL certificates and TLS/HSTS settings for Imperva Cloud WAF sites
category: imperva-cwaf
version: 2.0.0
---

# Imperva CWAF SSL Management

Manage SSL certificates and TLS/HSTS settings for Imperva Cloud WAF sites.

## Shared References

| Reference | Description |
|-----------|-------------|
| `../references/skill-dev-standard.md` | Dev standard |
| `../references/credential-and-identifier-policy.md` | Credential rules |
| `../references/shell-template-pattern.md` | Shell template patterns |

## Credential & Identifier Policy (MANDATORY)

| Value | Source | Method |
|-------|--------|--------|
| `IMPERVA_API_ID` | Bitwarden project `hermes-aws` | Only via `bws run --project-id 61c6c700-2d78-4860-b79e-b46200e193e9` |
| `IMPERVA_API_KEY` | Bitwarden project `hermes-aws` | Only via `bws run --project-id 61c6c700-2d78-4860-b79e-b46200e193e9` |
| `SITE_ID` | User / memory / get-site-detail | Pass as env var |
| `CAID` | User / memory / get-site-detail | Pass as env var |

**NEVER hardcode credentials or identifiers.**

## ⚡ MANDATORY: Use the Scripts

**ALWAYS use the provided scripts. Do NOT write inline curl.**

All scripts at: `~/.hermes/skills/imperva-cwaf/imperva-cwaf-ssl-management/templates/`

### Enable SSL Certificate (Imperva-Managed)

```bash
SITE_ID=<id> CAID=<caid> bws run --project-id <bw_id> -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-ssl-management/templates/enable-ssl.sh
```

### Get SSL Status

```bash
SITE_ID=<id> CAID=<caid> bws run --project-id <bw_id> -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-ssl-management/templates/get-ssl-status.sh
```

### Get Certificate Details

```bash
SITE_ID=<id> CAID=<caid> bws run --project-id <bw_id> -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-ssl-management/templates/get-certificate-details.sh
```

### Get TLS/HSTS Configuration

```bash
SITE_ID=<id> CAID=<caid> bws run --project-id <bw_id> -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-ssl-management/templates/get-tls-config.sh
```

### Update TLS/HSTS Configuration

```bash
# Default: ENHANCED_SECURITY + HSTS enabled
SITE_ID=<id> CAID=<caid> bws run --project-id <bw_id> -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-ssl-management/templates/update-tls-config.sh

# Custom settings
SITE_ID=<id> CAID=<caid> TLS_PROFILE=DEFAULT HSTS_ENABLED=false \
  bws run --project-id <bw_id> -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-ssl-management/templates/update-tls-config.sh
```

---

## TLS Configuration Profiles

| Profile | Description |
|---------|-------------|
| `DEFAULT` | Imperva's default TLS config |
| `CUSTOM` | Custom TLS (requires specifying versions/ciphers) |
| `ENHANCED_SECURITY` | Predefined enhanced security |

## HSTS Parameters

| Field | Default | Description |
|-------|---------|-------------|
| `isEnabled` | true | Enable HSTS |
| `maxAge` | 31536000 (1 year) | Browser remember time |
| `subDomainsIncluded` | false | Apply to subdomains |
| `preLoaded` | false | Submit to hstspreload.org |

---

## Pitfalls
- **SSL must be enabled before TLS/HSTS** — check SSL status first
- **CNAME validation required** — create CNAME record at DNS provider
- **Certificate provisioning takes a few minutes** — wait before checking
- **HSTS: test with short max-age first** before increasing
- **Subdomain HSTS** requires all subdomains to support HTTPS
- **Certificate renewal is automatic** for Imperva-managed certs

## Related Skills
- `imperva-cwaf-get-site-detail`: Get site IDs
- `imperva-cwaf-site-onboard`: Onboard new site
- `imperva-cwaf-policy-management`: Apply policies after SSL setup
