---
name: imperva-cwaf-delivery
description: Manage Imperva Cloud WAF delivery settings — compression, image compression, network optimization, redirection, and custom error pages.
category: imperva-cwaf
version: 1.0.0
---

# Imperva CWAF Delivery Settings Skill

Manage delivery settings for a site via the Imperva Cloud WAF API.

## Credential & Identifier Policy (MANDATORY)

### Credentials — ห้าม hardcode เด็ดขาด

| Value | Source | Method |
|-------|--------|--------|
| `IMPERVA_API_ID` | Bitwarden project `hermes-aws` | Only via `bws run --project-id 61c6c700-2d78-4860-b79e-b46200e193e9` |
| `IMPERVA_API_KEY` | Bitwarden project `hermes-aws` | Only via `bws run --project-id 61c6c700-2d78-4860-b79e-b46200e193e9` |

- **ห้าม** hardcode credential ใน script, template, หรือ SKILL.md
- **ห้าม** print credential ใน log หรือ raw request output
- **ห้าม** ใช้ credential จาก project `hermes` (auth ได้แต่ไม่มี write permission → 9415 error)
- **รูปแบบที่ถูกต้อง:** เขียน script ที่ reference `$IMPERVA_API_ID` / `$IMPERVA_API_KEY` จาก env แล้วส่งผ่าน `bws run` เท่านั้น
- bws inject เฉพาะ `IMPERVA_API_ID` กับ `IMPERVA_API_KEY` — ไม่มี SITE_ID/CAID

### Identifiers — ระบุแหล่งที่มาชัดเจน

| Value | Source | Method |
|-------|--------|--------|
| `SITE_ID` | User / memory / `imperva-cwaf-get-site-detail` skill | Pass เป็น env var ก่อนเรียก script |
| `CAID` | User / memory / `imperva-cwaf-get-site-detail` skill | Pass เป็น env var ก่อนเรียก script |

- SITE_ID กับ CAID **ไม่ใช่ credential** (เป็น public identifier) สามารถใส่ใน script ได้ แต่ต้องมาจาก user input — **ห้าม hardcode ใน template**
- templates ทั้งหมดใช้ `$SITE_ID` / `$CAID` จาก env var ที่ user ต้องกำหนดเอง

### Correct Usage Pattern

```bash
# ✅ CORRECT: credentials from bws run, identifiers from user env
SITE_ID=852056322 CAID=2429928 \
  bws run --project-id 61c6c700-2d78-4860-b79e-b46200e193e9 \
  -- bash templates/get-delivery.sh

# ✅ CORRECT: with additional params
SITE_ID=852056322 CAID=2429928 COMPRESSION_TYPE=BROTLI \
  bws run --project-id 61c6c700-2d78-4860-b79e-b46200e193e9 \
  -- bash templates/update-delivery-mode.sh

# ❌ WRONG: hardcoded credentials in script
# ❌ WRONG: hardcoded SITE_ID in template
# ❌ WRONG: print $IMPERVA_API_KEY in log output
```

## API Endpoint

```
/api/prov/v2/sites/{siteId}/settings/delivery
```

Base URL: `https://my.imperva.com`

## Operations

### Get Delivery Settings

```
GET /api/prov/v2/sites/{siteId}/settings/delivery?caid={caid}
```

**Query parameters:**
| Param | Type | Required | Description |
|---|---|---|---|
| `caid` | integer | ✅ | Account ID |
| `sections` | string | ❌ | Comma-separated sections to return. Valid: `compression`, `image_compression`, `network`, `redirection`, `custom_error_page` |

**Python pattern:**
```python
import json, urllib.request, os

site_id = "YOUR_SITE_ID"
caid = "YOUR_CAID"
api_id = os.environ["IMPERVA_API_ID"]
api_key = os.environ["IMPERVA_API_KEY"]

url = "https://my.imperva.com/api/prov/v2/sites/{s}/settings/delivery?caid={c}".format(s=site_id, c=caid)

req = urllib.request.Request(url)
req.add_header("Accept", "application/json")
req.add_header("x-API-Id", api_id)
req.add_header("x-API-Key", api_key)

resp = urllib.request.urlopen(req, timeout=30)
data = json.loads(resp.read().decode())
```

### Update Delivery Settings

```
PUT /api/prov/v2/sites/{siteId}/settings/delivery?caid={caid}
```

**Body:** Full `DeliverySettingsObject` — all sections must be included. Partial body returns 406 "failed to parse body".

**CRITICAL:** Do NOT include `port` or `ssl_port` fields. They are read-only and cause error 406 ("Invalid Port: The port number must be a valid integer"). Even sending `"to": "-"` triggers this error.

**Headers:** `Content-Type: application/json`

**Python pattern:**
```python
payload = {
    "compression": {
        "file_compression": True,
        "minify_js": True,
        "minify_css": True,
        "minify_static_html": True,
        "compression_type": "BROTLI"  # or "GZIP"
    },
    "image_compression": {
        "compress_jpeg": True,
        "progressive_image_rendering": False,
        "aggressive_compression": False,
        "compress_png": True
    },
    "network": {
        "tcp_pre_pooling": True,
        "origin_connection_reuse": True,
        "support_non_sni_clients": False,
        "enable_http2": True,
        "http2_to_origin": False
    },
    "redirection": {
        "redirect_naked_to_full": False,
        "redirect_http_to_https": False
    },
    "custom_error_page": {}
}
body = json.dumps(payload).encode()

req = urllib.request.Request(url, data=body, method="PUT")
req.add_header("Content-Type", "application/json")
```

## Response Structure

All operations return the full `DeliverySettingsObject`:

```json
{
  "compression": {
    "file_compression": true,
    "minify_js": true,
    "minify_css": true,
    "minify_static_html": true,
    "compression_type": "GZIP"
  },
  "image_compression": {
    "compress_jpeg": true,
    "progressive_image_rendering": false,
    "aggressive_compression": false,
    "compress_png": true
  },
  "network": {
    "tcp_pre_pooling": true,
    "origin_connection_reuse": true,
    "support_non_sni_clients": false,
    "enable_http2": true,
    "http2_to_origin": false,
    "port": { "from": "80", "to": "-" },
    "ssl_port": { "from": "443", "to": "-" }
  },
  "redirection": {
    "redirect_naked_to_full": false,
    "redirect_http_to_https": false
  },
  "custom_error_page": {}
}
```

## Delivery Settings Reference

### Compression
| Field | Type | Description |
|---|---|---|
| `file_compression` | boolean | Enable Gzip/Brotli compression for text resources |
| `compression_type` | string | `GZIP` (default) or `BROTLI` (recommended) |
| `minify_js` | boolean | Minify JavaScript |
| `minify_css` | boolean | Minify CSS (cached only) |
| `minify_static_html` | boolean | Minify static HTML (cached only) |

### Image Compression
| Field | Type | Description |
|---|---|---|
| `compress_jpeg` | boolean | Compress JPEG images |
| `progressive_image_rendering` | boolean | Progressive JPEG rendering |
| `aggressive_compression` | boolean | Aggressive JPEG compression (may reduce quality) |
| `compress_png` | boolean | Compress PNG images (removes metadata only, no quality loss) |

### Network
| Field | Type | Description |
|---|---|---|
| `tcp_pre_pooling` | boolean | Maintain idle TCP connections to origin |
| `origin_connection_reuse` | boolean | Keep TCP connections open for reuse |
| `support_non_sni_clients` | boolean | Support non-SNI clients (default: true) |
| `enable_http2` | boolean | Enable HTTP/2 for clients |
| `http2_to_origin` | boolean | Enable HTTP/2 to origin server |

### Redirection
| Field | Type | Description |
|---|---|---|
| `redirect_naked_to_full` | boolean | Redirect naked domain to www |
| `redirect_http_to_https` | boolean | Redirect HTTP to HTTPS |

### Custom Error Pages
| Field | Type | Description |
|---|---|---|
| `error_page_template` | string | Default error page HTML. Must include `$TITLE$` and `$BODY$` placeholders |
| `custom_error_page_templates` | object | Map of error type → HTML template. Send empty string to revert individual template to default |

**Custom error types** (all under `custom_error_page_templates`):
- `error.type.connection_timeout` — Connection Timeout
- `error.type.access_denied` — Access Denied
- `error.type.parse_req_error` — Unable to parse request
- `error.type.parse_resp_error` — Unable to parse response
- `error.type.connection_failed` — Unable to connect to origin server
- `error.type.ssl_failed` — Unable to establish SSL connection
- `error.type.deny_and_captcha` — Initial denied, CAPTCHA required
- `error.type.no_ssl_config` — Site not configured for SSL
- `error.type.abp_identification_failed` — ABP identification failed (no placeholders, body-only HTML)

## Pitfalls

- **ห้าม hardcode credential**: ห้ามใส่ API ID / API Key ใน script, template, หรือ log output เด็ดขาด — ต้องผ่าน `bws run` เท่านั้น
- **ห้าม hardcode identifier ใน template**: SITE_ID / CAID ต้องมาจาก user env var ไม่ใช่ค่า fix ใน template
- **PUT requires full body**: Despite spec saying "partial update", the API returns 406 "failed to parse body" if you send only the changed section. Always send all sections.
- **port/ssl_port are read-only**: Never include `port` or `ssl_port` in PUT body. Including them causes error 406 "Invalid Port". The response will include them read-only.
- **bws run env injection**: `bws run` injects only `IMPERVA_API_ID` and `IMPERVA_API_KEY`. It does NOT inject `SITE_ID` or `CAID`. User must pass those as env vars.
- **Python env var access**: Use `os.environ["IMPERVA_API_ID"]` (not `$IMPERVA_API_ID` in Python). Env vars expand naturally in shell scripts run via `bws run`.
- **Compression type enum**: Only `GZIP` and `BROTLI`. Case-sensitive.
- **Write file proxy issue**: When writing Python scripts via `write_file`, avoid inline `$` patterns in DictFormat strings — the proxy may interpret them as env vars. Use `.format(s=..., c=...)` with named params, or write via a template file.

## Related Skills

- `imperva-cwaf-api-manual`: For browsing API specifications. Delivery spec at `api-spec/delivery-api.yaml`
- `imperva-cwaf-get-site-detail`: Get site IDs and current configuration
- `imperva-cwaf-cache`: For managing cache settings and cache rules
- `imperva-cwaf-custom-rule`: For managing WAF custom rules
- `imperva-cwaf-policy-management`: For managing WAF policies (ACL, Whitelist, etc.)
- `imperva-cwaf-ssl-management`: For managing SSL certificates and TLS/HSTS settings

## Skill Development Reference

For the standard Imperva CWAF skill development pattern:
- `references/credential-and-identifier-policy.md` — credential/identifier sourcing rules (no hardcode)
- `references/shell-template-pattern.md` — standard shell template structure (GET→modify→PUT)
