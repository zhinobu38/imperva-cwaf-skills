---
name: imperva-cwaf-delivery
description: Manage Imperva Cloud WAF delivery settings — compression, image compression, network optimization, redirection, and custom error pages.
category: imperva-cwaf
version: 3.0.0
---

# Imperva CWAF Delivery Settings

Manage delivery settings (compression, image compression, network, redirection, error pages) for a site.

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

All scripts at: `~/.hermes/skills/imperva-cwaf/imperva-cwaf-delivery/templates/`

### Get Delivery Settings

```bash
SITE_ID=<id> CAID=<caid> bws run --project-id <bw_id> -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-delivery/templates/get-delivery.sh
```

Optional: `SECTIONS=compression,image_compression,network,redirection,custom_error_page` to filter.

### Update Compression Settings

```bash
SITE_ID=<id> CAID=<caid> COMPRESSION_TYPE=BROTLI \
  bws run --project-id <bw_id> -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-delivery/templates/update-delivery-mode.sh
```

Env vars: `COMPRESSION_TYPE`, `FILE_COMPRESSION`, `MINIFY_JS`, `MINIFY_CSS`, `MINIFY_STATIC_HTML`

### Update Image Compression Settings

```bash
SITE_ID=<id> CAID=<caid> COMPRESS_JPEG=true COMPRESS_PNG=true \
  bws run --project-id <bw_id> -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-delivery/templates/update-image-compression.sh
```

Env vars: `COMPRESS_JPEG`, `COMPRESS_PNG`, `AGGRESSIVE_COMPRESSION`, `PROGRESSIVE_IMAGE_RENDERING`

### Update Network Settings

```bash
SITE_ID=<id> CAID=<caid> ENABLE_HTTP2=true HTTP2_TO_ORIGIN=false \
  bws run --project-id <bw_id> -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-delivery/templates/update-network.sh
```

Env vars: `TCP_PRE_POOLING`, `ORIGIN_CONNECTION_REUSE`, `SUPPORT_NON_SNI_CLIENTS`, `ENABLE_HTTP2`, `HTTP2_TO_ORIGIN`

### Update Redirection Settings

```bash
SITE_ID=<id> CAID=<caid> REDIRECT_HTTP_TO_HTTPS=true \
  bws run --project-id <bw_id> -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-delivery/templates/update-redirection.sh
```

Env vars: `REDIRECT_NAKED_TO_FULL`, `REDIRECT_HTTP_TO_HTTPS`

### Set Custom Error Page

```bash
SITE_ID=<id> CAID=<caid> ERROR_TYPE=access_denied \
  ERROR_HTML='<html><body>Access Denied</body></html>' \
  bws run --project-id <bw_id> -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-delivery/templates/set-error-page.sh
```

To remove a custom error page, set `ERROR_HTML=''`.

Supported `ERROR_TYPE` values: `connection_timeout`, `access_denied`, `parse_req_error`, `parse_resp_error`, `connection_failed`, `ssl_failed`, `deny_and_captcha`, `no_ssl_config`, `abp_identification_failed`

### Restore Default Delivery Settings

```bash
SITE_ID=<id> CAID=<caid> bws run --project-id <bw_id> -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-delivery/templates/restore-defaults.sh
```

---

## Settings Reference

### Compression
| Field | Type | Values |
|-------|------|--------|
| `file_compression` | boolean | Enable Gzip/Brotli |
| `compression_type` | string | `GZIP` or `BROTLI` |
| `minify_js` | boolean | Minify JavaScript |
| `minify_css` | boolean | Minify CSS |
| `minify_static_html` | boolean | Minify static HTML |

### Image Compression
| Field | Type | Values |
|-------|------|--------|
| `compress_jpeg` | boolean | Compress JPEG images |
| `compress_png` | boolean | Compress PNG images |
| `aggressive_compression` | boolean | Aggressive JPEG compression (may impact quality) |
| `progressive_image_rendering` | boolean | Progressive image rendering |

### Network
| Field | Type | Values |
|-------|------|--------|
| `tcp_pre_pooling` | boolean | Maintain idle TCP connections |
| `origin_connection_reuse` | boolean | Reuse TCP connections for additional requests |
| `support_non_sni_clients` | boolean | Support non-SNI clients (default: true) |
| `enable_http2` | boolean | Enable HTTP/2 for clients |
| `http2_to_origin` | boolean | HTTP/2 to origin server |

### Redirection
| Field | Type | Values |
|-------|------|--------|
| `redirect_naked_to_full` | boolean | Naked → www |
| `redirect_http_to_https` | boolean | HTTP → HTTPS |

### Custom Error Pages
| Field | Type | Values |
|-------|------|--------|
| `error_page_template` | string | Default error page HTML template |
| `custom_error_page_templates` | object | Per-error-type custom pages |

---

## Pitfalls
- **PUT supports partial update** — only send the sections you want to change. No need to GET first (except `update-delivery-mode.sh` which uses GET→modify→PUT full body for safety).
- **Compression type requires full body PUT** — partial PUT on `compression` with `compression_type` field fails with res 3015 "Internal error" for both GZIP and BROTLI. `update-delivery-mode.sh` handles this by GET→modify→PUT full body with `del(.network.port/.ssl_port)`.
- **port/ssl_port objects must be deleted before PUT** — including `port` or `ssl_port` objects in PUT body causes res 2 "Invalid Port". Always use `del(.network.port)` and `del(.network.ssl_port)` before any full-body PUT. The `from` sub-fields are read-only; the `to` sub-fields are writable but the safest approach is to delete both objects entirely.
- **Compression type enum** — only `GZIP` and `BROTLI` (case-sensitive). Any other value causes res 3015.
- **bws run injects only API ID/Key** — SITE_ID/CAID must be passed as env vars
- **Image compression requires caching** — image compression only applies to cached images. If caching is disabled, these settings have no effect.
- **redirect_naked_to_full** — only applicable for naked domains (without www)
- **redirect_http_to_https** — only applicable for SSL-enabled sites
- **Custom error page placeholders** — most error page templates require `$TITLE$` and `$BODY$` placeholders. Exception: `abp_identification_failed` does not support placeholders.

## Related Skills
- `imperva-cwaf-get-site-detail`: Get site IDs
- `imperva-cwaf-cache`: Cache settings
- `imperva-cwaf-ssl-management`: SSL/TLS settings

## References
- `references/api-quirks.md` — API behavior that deviates from the OpenAPI spec (partial PUT quirks, read-only fields, placeholder requirements)
