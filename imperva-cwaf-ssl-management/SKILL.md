---
name: imperva-cwaf-ssl-management
description: Manage SSL certificates and TLS/HSTS settings for Imperva Cloud WAF sites
category: imperva-cwaf
version: 2.1.0
---

# Imperva CWAF SSL Management

Manage SSL certificates and TLS/HSTS settings for Imperva Cloud WAF sites.

## Shared References

| Reference | Description |
|-----------|-------------|
| `../../references/skill-dev-standard.md` | Dev standard: template structure, credential rules, known API behaviors, pitfalls |
| `../../references/credential-and-identifier-policy.md` | Credential/identifier sourcing rules (Bitwarden bws run) |
| `../../references/shell-template-pattern.md` | Shell template patterns (GET→modify→PUT, form-encoded POST, header format) |
| `references/api-endpoint-reference.md` | API endpoint details, base URLs, schemas |
| `references/api-base-url-reference.md` | **v3 API base URL mapping** — critical rules for certificates-ui vs sites-mgmt vs v1 |

**NEVER hardcode credentials or identifiers.** See `credential-and-identifier-policy.md` for full rules.

## ⚡ MANDATORY: Use the Scripts

**ALWAYS use the provided scripts. Do NOT write inline curl.**

All scripts at: `~/.hermes/skills/imperva-cwaf/imperva-cwaf-ssl-management/scripts/`

### Enable SSL Certificate (Imperva-Managed)

```bash
SITE_ID=<id> CAID=<caid> bws run --project-id <bw_id> -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-ssl-management/scripts/enable-ssl.sh
```

### Get SSL Status

```bash
SITE_ID=<id> CAID=<caid> bws run --project-id <bw_id> -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-ssl-management/scripts/get-ssl-status.sh
```

### Get Certificate Details

```bash
SITE_ID=<id> CAID=<caid> bws run --project-id <bw_id> -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-ssl-management/scripts/get-certificate-details.sh
```

### Get TLS/HSTS Configuration

```bash
SITE_ID=<id> CAID=<caid> bws run --project-id <bw_id> -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-ssl-management/scripts/get-tls-config.sh
```

### Update TLS/HSTS Configuration

```bash
# Default: ENHANCED_SECURITY + HSTS enabled
SITE_ID=<id> CAID=<caid> bws run --project-id <bw_id> -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-ssl-management/scripts/update-tls-config.sh

# Custom settings
SITE_ID=<id> CAID=<caid> TLS_PROFILE=DEFAULT HSTS_ENABLED=false \
  bws run --project-id <bw_id> -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-ssl-management/scripts/update-tls-config.sh
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

## Response Structure

### GET /certificates/managed (SSL Status)

```json
{
  "data": [{
    "siteId": 852056322,
    "defaultValidationMethod": "CNAME",
    "siteCertificateEnabled": true,
    "certificateDetails": [{
      "id": 226642,
      "name": "ATLAS_114-1780117274442",
      "status": "ACTIVE",
      "type": "MANAGED",
      "expirationDate": 1787893284000,
      "inRenewal": false,
      "sans": [...],
      "extSiteId": 852056322,
      "authType": "RSA",
      "level": "SITE"
    }]
  }]
}
```

### GET /certificates (Certificate Details)

```json
{
  "data": [{
    "id": 226642,
    "name": "ATLAS_114-1780117274442",
    "status": "ACTIVE",
    "type": "MANAGED",
    "expirationDate": 1787893284000,
    "sans": [{
      "sanId": 2637328,
      "sanValue": "testagent.thtechs.com",
      "validationMethod": "CNAME",
      "status": "VALIDATED"
    }],
    "extSiteId": 852056322,
    "siteName": "testagent.thtechs.com"
  }]
}
```

### GET /settings/TLSConfiguration

```json
{
  "data": [{
    "hstsConfiguration": {
      "isEnabled": true,
      "maxAge": 31536000,
      "subDomainsIncluded": false,
      "preLoaded": false
    },
    "inboundTlsSettings": {
      "configurationProfile": "ENHANCED_SECURITY"
    },
    "disablePQCSupport": false
  }]
}
```

### POST /certificates/managed (Enable/Disable SSL)

Response same as GET — returns full `data[]` envelope with updated settings.

### PATCH /settings/TLSConfiguration (Update TLS/HSTS)

Response same as GET — returns full `data[]` envelope with updated settings.

## Error Handling

| Code | HTTP | Meaning | Resolution |
|------|------|---------|------------|
| 200 | 200 | Success | — |
| 400 | 400 | Bad request (invalid params) | Check request body format |
| 401 | 401 | Unauthorized | Check Bitwarden credentials |
| 405 | 405 | Method not supported | Use POST for /certificates/managed, not PUT |
| 403 | 403 | WAF intermittent block (errorCode 15) | Retry with exponential backoff (5s, 15s, 30s, 60s) |
| 429 | 429 | Rate limited | Wait and retry |
| 9415 | 200 | Operation not allowed | Check Bitwarden project (must be `hermes-aws`) |
| 1003 | 200 | Unauthorized request for account | Check CAID value |

## Pitfalls

- **SSL must be enabled before TLS/HSTS** — check SSL status first
- **CNAME validation required** — create CNAME record at DNS provider
- **Certificate provisioning takes a few minutes** — wait before checking
- **HSTS: test with short max-age first** before increasing
- **Subdomain HSTS** requires all subdomains to support HTTPS
- **Certificate renewal is automatic** for Imperva-managed certs
- **certificates-ui base URL**: `/certificates/managed` endpoints MUST use `https://api.imperva.com/certificates-ui/v3/` NOT `https://api.imperva.com/sites-mgmt/v3/`. Wrong base URL causes persistent WAF blocks (errorCode 15) that don't resolve with retry.
- **POST not PUT for enable/disable**: Use `POST /certificates/managed` to enable/disable SSL. PUT returns 405 "Request method 'PUT' is not supported". DELETE is deprecated.
- **Response wrapper**: `/certificates/managed` responses use `{"data": [...]}` envelope, not flat objects.
- **WAF intermittent blocks on v3 API**: The `api.imperva.com` endpoints (v3) are more frequently blocked by Imperva's own WAF than `my.imperva.com` (v1). Always implement exponential backoff retry (5s, 15s, 30s, 60s) for v3 calls.

## Related Skills

- `imperva-cwaf-get-site-detail`: Get site IDs
- `imperva-cwaf-site-onboard`: Onboard new site
- `imperva-cwaf-policy-management`: Apply policies after SSL setup
