# Imperva CWAF API Base URL Reference

## v3 API Base URL Mapping

Imperva v3 API uses **different base URLs depending on the service**. Mixing them causes WAF blocks (errorCode 15) or 405 errors.

| Service | Base URL | Example |
|---------|----------|---------|
| Certificate Management | `https://api.imperva.com/certificates-ui/v3/` | `/sites/{siteId}/certificates/managed` |
| Site Settings (TLS/HSTS, bot, delivery, cache) | `https://api.imperva.com/sites-mgmt/v3/` | `/sites/{siteId}/settings/TLSConfiguration` |
| Security (v1) | `https://my.imperva.com/api/prov/v1/` | `/sites/configure/security` |
| Site Management (v1) | `https://my.imperva.com/api/prov/v1/` | `/sites/status` |

## Critical Rules

1. **Never use `sites-mgmt` for certificate endpoints** — `/certificates/managed` only works under `certificates-ui`. Wrong base URL causes persistent WAF blocks (errorCode 15) that don't resolve with retry.
2. **POST not PUT for `/certificates/managed`** — Use POST to enable/disable SSL. PUT returns 405. DELETE is deprecated.
3. **PATCH for `/settings/TLSConfiguration`** — Partial update via PATCH, not PUT.
4. **v3 endpoints use JSON body** — `Content-Type: application/json`. v1 endpoints use form-encoded.
5. **v3 WAF sensitivity** — `api.imperva.com` (v3) endpoints are more frequently blocked by Imperva's own WAF than `my.imperva.com` (v1). Always implement exponential backoff retry (5s, 15s, 30s, 60s) for v3 calls.

## Response Envelope Patterns

| API | Response Wrapper |
|-----|-----------------|
| `/certificates/managed` (GET/POST) | `{"data": [{...}]}` |
| `/certificates` (GET) | `{"data": [{...}]}` |
| `/settings/TLSConfiguration` (GET/PATCH) | `{"data": [{...}]}` |
| `/settings/botConfiguration` (GET/POST) | `{"data": [{...}]}` |
| Security v1 (POST) | Flat object with `res`, `res_message` |
| Site status v1 (POST) | Flat object with `security.waf.rules[]` |
