# Delivery API Quirks & Notes

Session-derived knowledge about Imperva CWAF Delivery API behavior that deviates from the OpenAPI spec.

## Partial PUT Behavior

The delivery API spec (`delivery-api.yaml`) states PUT is a "partial update" — only specified fields are modified. In practice:

| Section | Partial PUT | Notes |
|---------|-------------|-------|
| `compression` | ⚠️ Partial works, but NOT for `compression_type` | `compression_type` (GZIP/BROTLI) requires full-body PUT. Other compression fields (file_compression, minify_js, etc.) work with partial PUT. `update-delivery-mode.sh` uses GET→modify→PUT full body for safety. |
| `image_compression` | ✅ Works | `update-image-compression.sh` uses partial PUT |
| `network` | ✅ Works | Partial PUT works for all network fields. `update-network.sh` still uses GET→modify→PUT full body for consistency. |
| `redirection` | ✅ Works | `update-redirection.sh` uses partial PUT |
| `custom_error_page` | ✅ Works (partial) | `set-error-page.sh` uses GET→modify→PUT full body for safety |

## Read-Only Fields

- `network.port` — entire object is read-only (both `from` and `to` sub-fields)
- `network.ssl_port` — entire object is read-only
- Including these objects in PUT body causes res 2 "Invalid Port"
- Always `del(.network.port)` and `del(.network.ssl_port)` before PUT when using full-body approach

## Custom Error Page Placeholders

Most error types require `$TITLE$` and `$BODY$` placeholders in the HTML template. Without them, API returns `res 2 Invalid input` with message: "The error page template must contain the following placeholders - $TITLE$ and $BODY$"

Exception: `error.type.abp_identification_failed` does NOT support placeholders.

## Error Types for Custom Error Pages

All supported `ERROR_TYPE` values (used as `error.type.<value>` key):
- `connection_timeout`
- `access_denied`
- `parse_req_error`
- `parse_resp_error`
- `connection_failed`
- `ssl_failed`
- `deny_and_captcha`
- `no_ssl_config`
- `abp_identification_failed`

## Compression Type

- Only `GZIP` and `BROTLI` are valid (case-sensitive)
- Any other value causes res 3015 "Internal error"
- **Partial PUT with `compression_type` fails** — must use GET→modify→PUT full body to change compression type

## Image Compression Dependency

Image compression settings only apply to cached images. If site caching is disabled, these settings have no effect.

## Redirection Constraints

- `redirect_naked_to_full` — only applicable/visible for naked domains (without www prefix)
- `redirect_http_to_https` — only applicable/visible for SSL-enabled sites

## Sections Filter (GET)

Valid `sections` query parameter values for GET:
- `compression`
- `image_compression`
- `network`
- `redirection`
- `custom_error_page`

Multiple sections can be comma-separated: `SECTIONS=compression,network`
