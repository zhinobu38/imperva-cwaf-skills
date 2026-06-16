---
name: imperva-cwaf-lb-delivery
description: "Manage Imperva Cloud WAF — origin servers, load balancing, and delivery settings. Use when configuring origin/DC setup, LB algorithms, compression, redirection, or custom error pages for Imperva CWAF sites."
category: imperva-cwaf
version: 1.1.0
---

# Imperva CWAF — Load Balancing & Delivery

Manage origin servers, load balancing, compression, redirection, and error pages for Imperva CWAF sites.

## Credential & Identifier Policy (MANDATORY)

| Value | Source | Method |
|-------|--------|--------|
| `IMPERVA_API_ID` | Bitwarden project `hermes-aws` | Only via `bws run --project-id 61c6c700-2d78-4860-b79e-b46200e193e9` |
| `IMPERVA_API_KEY` | Bitwarden project `hermes-aws` | Only via `bws run --project-id 61c6c700-2d78-4860-b79e-b46200e193e9` |
| `SITE_ID` | User / memory / get-site-detail | Pass as env var |
| `CAID` | User / memory / get-site-detail | Pass as env var |

**NEVER hardcode credentials or identifiers.**

## ⚡ MANDATORY: Use the Scripts

**ALWAYS use the provided scripts. Do NOT write inline curl or Python.**

All scripts at: `~/.hermes/skills/imperva-cwaf/imperva-cwaf-lb-delivery/scripts/`

---

## §1: Delivery Settings

Manage delivery settings (compression, image compression, network, redirection, error pages) for a site.

### Get Delivery Settings

```bash
SITE_ID=<id> CAID=<caid> bws run --project-id <bw_id> -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-lb-delivery/scripts/get-delivery.sh
```

Optional: `SECTIONS=compression,image_compression,network,redirection,custom_error_page` to filter.

### Update Compression Settings

```bash
SITE_ID=<id> CAID=<caid> COMPRESSION_TYPE=BROTLI \
  bws run --project-id <bw_id> -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-lb-delivery/scripts/update-delivery-mode.sh
```

Env vars: `COMPRESSION_TYPE`, `FILE_COMPRESSION`, `MINIFY_JS`, `MINIFY_CSS`, `MINIFY_STATIC_HTML`

### Update Image Compression Settings

```bash
SITE_ID=<id> CAID=<caid> COMPRESS_JPEG=true COMPRESS_PNG=true \
  bws run --project-id <bw_id> -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-lb-delivery/scripts/update-image-compression.sh
```

### Update Network Settings

```bash
SITE_ID=<id> CAID=<caid> ENABLE_HTTP2=true HTTP2_TO_ORIGIN=false \
  bws run --project-id <bw_id> -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-lb-delivery/scripts/update-network.sh
```

### Update Redirection Settings

```bash
SITE_ID=<id> CAID=<caid> REDIRECT_HTTP_TO_HTTPS=true \
  bws run --project-id <bw_id> -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-lb-delivery/scripts/update-redirection.sh
```

### Set Custom Error Page

```bash
SITE_ID=<id> CAID=<caid> ERROR_TYPE=access_denied \
  ERROR_HTML='<html><body>Access Denied</body></html>' \
  bws run --project-id <bw_id> -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-lb-delivery/scripts/set-error-page.sh
```

### Restore Default Delivery Settings

```bash
SITE_ID=<id> CAID=<caid> bws run --project-id <bw_id> -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-lb-delivery/scripts/restore-defaults.sh
```

### Delivery Settings Reference

See `references/api-quirks.md` for API behavior that deviates from the OpenAPI spec.

### Delivery Pitfalls
- **PUT supports partial update** — only send the sections you want to change
- **Compression type requires full body PUT** — partial PUT on `compression` with `compression_type` field fails with res 3015
- **port/ssl_port objects must be deleted before PUT** — including `port` or `ssl_port` objects in PUT body causes res 2 "Invalid Port"
- **Compression type enum** — only `GZIP` and `BROTLI` (case-sensitive)
- **Image compression requires caching** — only applies to cached images
- **redirect_naked_to_full** — only applicable for naked domains
- **redirect_http_to_https** — only applicable for SSL-enabled sites
- **Custom error page placeholders** — most require `$TITLE$` and `$BODY$` placeholders

---

## §2: Load Balancing

Manage load balancing, data center, and origin server settings for a site.

### Get Load Balancing Configuration

```bash
SITE_ID=<id> CAID=<caid> bws run --project-id <bw_id> -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-lb-delivery/scripts/get-load-balancing.sh
```

### Update Load Balancing Configuration

```bash
# Step 1: GET current config
# Step 2: Modify JSON
# Step 3: Pipe modified JSON into update script
SITE_ID=<id> CAID=<caid> bws run --project-id <bw_id> -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-lb-delivery/scripts/update-load-balancing.sh < modified.json
```

### Resume Traffic to Active DCs

```bash
SITE_ID=<id> CAID=<caid> bws run --project-id <bw_id> -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-lb-delivery/scripts/resume-dc.sh
```

### Global LB Algorithms

| Algorithm | Description |
|-----------|-------------|
| `BEST_CONNECTION_TIME` | Route to fastest DC |
| `GEO_PREFERRED` | Prefer geo-matched DC |
| `GEO_REQUIRED` | Require geo-matched DC |
| `WEIGHTED_LB` | Weighted distribution |

### Data Center Modes

| Mode | Description |
|------|-------------|
| `SINGLE_SERVER` | No LB |
| `SINGLE_DC` | LB within DC |
| `MULTIPLE_DC` | LB across DCs + geo routing |

### Load Balancing Pitfalls
- **PUT is full replacement** — always GET first, modify, then PUT
- **At least 1 DC must be enabled** — cannot disable all
- **At least 1 server per DC must be enabled**
- **Max 1 standby DC** per site
- **GEO mode requires `isRestOfTheWorld`** on exactly 1 DC
- **WEIGHTED_LB weights must sum to 100**
- **port/ssl_port are read-only** — never include in PUT body
- **Resume is manual** — traffic does not auto-revert after failover

---

## Related Skills

- `imperva-cwaf-ssl-management`: SSL/TLS settings
- `imperva-cwaf-cache`: Cache settings
- `imperva-cwaf-policy-management`: WAF rules, ACL, whitelist
- `imperva-cwaf-site-onboard`: Onboard new sites
- `imperva-cwaf-get-site-detail`: Get site IDs
- `imperva-cwaf-status-check`: Check service operational status
- `imperva-cwaf-custom-rule`: Create/manage custom WAF rules

## References

- `references/api-quirks.md` — API behavior that deviates from the OpenAPI spec (partial PUT quirks, read-only fields, placeholder requirements)
