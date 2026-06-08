---
name: imperva-cwaf-cache
description: Manage Imperva Cloud WAF cache settings, custom cache rules, client-side caching, response header caching, and cache purging via the API.
category: imperva-cwaf
version: 1.1.0
---

# Imperva CWAF Cache Management

Manage all cache-related settings for Imperva Cloud WAF sites via the Cache API v2.

## Prerequisites

- API credentials (ID and Key) for Imperva Cloud WAF — always retrieve from Bitwarden.
- Site ID of the target website (use `imperva-cwaf-get-site-detail` if unknown).
- All Imperva CWAF operations must be delegated to the `imperva-agent` profile.

## Credential Retrieval (MANDATORY)

**ALWAYS retrieve API credentials from Bitwarden (bws).** Never use local env vars or hardcoded values.

Use project `hermes-aws` (ID: `<BW_PROJECT_ID_WRITE>`), NOT the `hermes` project.

Quick pattern:
```bash
# Write script without credentials, then run via bws run
bws run --project-id <BW_PROJECT_ID_WRITE> -- python3 /tmp/script.py
```

For simple curl calls, use a shell script (env vars expand naturally):
```bash
bws run --project-id <BW_PROJECT_ID_WRITE> -- bash /tmp/script.sh
```

## API Base

All endpoints are under:
```
https://my.imperva.com/api/prov/v2
```

## Authentication Headers

All requests require:
```
Accept: application/json
x-API-Id: <api_id>
x-API-Key: <api_key>
Content-Type: application/json   (for PUT/POST/DELETE with body)
```

## Response Format

The Cache API uses a legacy response envelope (different from other Imperva APIs):
```json
{
  "res": 0,
  "res_message": "OK",
  "debug_info": {
    "id-info": "999999"
  }
}
```

- `res`: 0 = success, non-zero = error
- `res_message`: human-readable status
- GET responses return the actual object directly (not wrapped in `value`)
- Cache rule POST returns `{"rule_id": N, "res": 0, ...}` (note: `rule_id` not `id`)
- Empty cache rule list returns `{"res": 0, "res_message": "OK", "debug_info": {"Site has no Cache rules": "..."}}`

---

## 1. Cache Mode Settings

### Get Cache Settings

```
GET /sites/{siteId}/settings/cache
```

Optional query param `sections` to filter specific sections (comma-separated):
- `mode` — caching level and HTTPS settings
- `key` — cache key behavior
- `response` — response caching options
- `ttl` — TTL conflict resolution
- `client_side` — client-side caching

If `sections` is omitted, all sections are returned.

```bash
# Get all cache settings
bws run --project-id <BW_PROJECT_ID_WRITE> -- bash /tmp/get_cache_settings.sh

# Get only mode and client_side sections
bws run --project-id <BW_PROJECT_ID_WRITE> -- bash /tmp/get_cache_mode.sh
```

### Update Cache Settings (Partial)

```
PUT /sites/{siteId}/settings/cache
```

**Body is flat JSON** — no `data` wrapper. Only specified fields are modified.

**Note:** PUT for cache settings works as partial update — only fields in the body are changed. Other fields retain their current values. No `Force-Risky-Operation` header needed for settings updates.

```bash
bws run --project-id <BW_PROJECT_ID_WRITE> -- bash /tmp/update_cache_mode.sh
```

### Restore Default Cache Settings

```
DELETE /sites/{siteId}/settings/cache
```

Restores all cache settings to their default values.

### Cache Mode Levels

| Level | Description |
|-------|-------------|
| `disabled` | Turn off site caching entirely, including custom cache rules |
| `custom_cache_rules_only` | Disable caching unless specified otherwise by a custom cache rule |
| `standard` | Cache according to standard HTTP headers |
| `smart` | Cache standard HTTP headers + profile dynamic pages to identify static content |
| `all_resources` | Cache every resource on the web server for the specified TTL |

### HTTPS Caching Levels

| Level | Description |
|-------|-------------|
| `disabled` | No resources cached over HTTPS |
| `dont_include_html` | Only images, CSS, JS, and Cache-Control: public resources |
| `include_html` | Same as above + HTML files |
| `include_all_resources` | All resources may be cached over HTTPS |

---

## 2. Custom Cache Rule Management

Cache rules define exceptions to the general caching policy. They are evaluated in order.

### List All Cache Rules

```
GET /sites/{siteId}/settings/cache/rules
```

### Get a Specific Cache Rule

```
GET /sites/{siteId}/settings/cache/rules/{ruleId}
```

### Create a Cache Rule

```
POST /sites/{siteId}/settings/cache/rules
```

**Body is flat JSON** — no `data` wrapper.

Required fields: `name`, `action`, `enabled`, `filter`

```bash
bws run --project-id <BW_PROJECT_ID_WRITE> -- bash /tmp/create_cache_rule.sh
```

### Update a Cache Rule (Partial)

```
PUT /sites/{siteId}/settings/cache/rules/{ruleId}
```

**Important:** Despite the spec saying "partial update", the cache rule PUT requires the **full rule object** in the body. Sending only changed fields will return `{"res": 2, "res_message": "Invalid input", "debug_info": {"params": "no parameters given"}}`. Include all fields: `name`, `action`, `enabled`, `filter`, and any action-specific parameters (`ttl`, `text`, `ignored_params`, `differentiate_by_value`).

**Also:** Add the `Force-Risky-Operation: true` header to avoid 406 errors.

```bash
# Write full rule JSON to file, then:
bws run --project-id <BW_PROJECT_ID_WRITE> -- python3 /tmp/update_rule.py
```

### Delete a Cache Rule

```
DELETE /sites/{siteId}/settings/cache/rules/{ruleId}
```

### Cache Rule Actions

| Action | Description |
|--------|-------------|
| `HTTP_CACHE_MAKE_STATIC` | Always cache the resource |
| `HTTP_CACHE_CLIENT_CACHE_CTL` | Cache the resource on the client |
| `HTTP_CACHE_FORCE_UNCACHEABLE` | Never cache the resource |
| `HTTP_CACHE_ADD_TAG` | Tag resources for later tag-based purging |
| `HTTP_CACHE_ENABLE_ASYNC_VALIDATION` | Serve stale content when origin is unreachable |
| `HTTP_CACHE_DIFFERENTIATE_SSL` | Cache separately for HTTP vs HTTPS |
| `HTTP_CACHE_DIFFERENTIATE_BY_HEADER` | Differentiate cache key by header value |
| `HTTP_CACHE_DIFFERENTIATE_BY_COOKIE` | Differentiate cache key by cookie value |
| `HTTP_CACHE_DIFFERENTIATE_BY_GEO` | Differentiate cache key by geolocation |
| `HTTP_CACHE_IGNORE_PARAMS` | Ignore query parameters in cache key |
| `HTTP_CACHE_ENRICH_CACHE_KEY` | Add text suffix to cache key |
| `HTTP_CACHE_FORCE_VALIDATION` | Force user authentication with origin |
| `HTTP_CACHE_IGNORE_AUTH_HEADER` | Cache authenticated resources |

See `references/cache-rule-actions.md` for action-specific parameters.

### Cache Rule Conditional Parameters

Some actions require additional parameters:

| Parameter | Type | Relevant Actions |
|-----------|------|-----------------|
| `ttl` | integer (seconds) | `HTTP_CACHE_MAKE_STATIC`, `HTTP_CACHE_CLIENT_CACHE_CTL` |
| `ignored_params` | array of strings | `HTTP_CACHE_IGNORE_PARAMS` (use `["*"]` for all) |
| `text` | string | `HTTP_CACHE_ADD_TAG` (tag name), `HTTP_CACHE_ENRICH_CACHE_KEY` (suffix) |
| `differentiate_by_value` | string | `HTTP_CACHE_DIFFERENTIATE_BY_HEADER`, `HTTP_CACHE_DIFFERENTIATE_BY_COOKIE`, `HTTP_CACHE_DIFFERENTIATE_BY_GEO` |

---

## 3. Client-Side Cache

Client-side caching controls whether content is cached on client browsers/applications (not just Imperva proxies).

Settings are part of the main cache settings object under `client_side`:

| Field | Type | Description |
|-------|------|-------------|
| `enable_client_side_caching` | boolean | Cache content on client browsers |
| `comply_no_cache` | boolean | Comply with No-Cache and Max-Age in client requests |
| `send_age_header` | boolean | Send Cache-Control: max-age and Age headers |

Update via PUT to `/sites/{siteId}/settings/cache`:
```json
{
  "client_side": {
    "enable_client_side_caching": true,
    "comply_no_cache": false,
    "send_age_header": true
  }
}
```

---

## 4. Response Header Cache

Control which response headers are cached along with the resource.

Settings are part of the main cache settings object under `response.cache_response_header`:

| Field | Type | Description |
|-------|------|-------------|
| `mode` | string | `disabled`, `all`, or `custom` |
| `headers` | array of strings | Header names to cache (only when mode=custom) |

Update via PUT to `/sites/{siteId}/settings/cache`:
```json
{
  "response": {
    "cache_response_header": {
      "mode": "custom",
      "headers": ["Access-Control-Allow-Origin", "Access-Control-Allow-Methods"]
    }
  }
}
```

Other response-related settings:

| Field | Type | Description |
|-------|------|-------------|
| `response.stale_content.mode` | string | `disabled`, `adaptive`, `custom` |
| `response.stale_content.time` | integer | Stale content TTL in seconds (mode=custom) |
| `response.cache_shield` | boolean | Enable intermediate cache shield |
| `response.tag_response_header` | string | Header name containing cache tags |
| `response.cache_empty_responses` | boolean | Cache responses without body |
| `response.cache_300x` | boolean | Cache 301/302/303/307/308 redirects |
| `response.cache_http_10_responses` | boolean | Cache HTTP 1.0 without Content-Length |
| `response.cache_404.enabled` | boolean | Cache 404 responses |
| `response.cache_404.time` | integer | 404 cache TTL in seconds |

---

## 5. Cache Purge (URL-Based)

Purge cached content by URL pattern.

```
DELETE /sites/{siteId}/cache
```

Query parameters:

| Parameter | Type | Description |
|-----------|------|-------------|
| `url_pattern` | string | URL pattern to match for purging |
| `tags` | string | Comma-separated tag names (not used — URL-based only) |

URL pattern syntax:
- `resource_name` — resources containing the name
- `^resource_name` — resources starting with the name
- `resource_name$` — resources ending with the name

```bash
# Purge all resources containing "style.css"
bws run --project-id <BW_PROJECT_ID_WRITE> -- bash /tmp/purge_cache.sh

# Purge all resources under /images/
bws run --project-id <BW_PROJECT_ID_WRITE> -- bash /tmp/purge_cache_path.sh
```

---

## Cache Key Settings

Control how cache keys are generated (part of main cache settings under `key`):

| Field | Type | Description |
|-------|------|-------------|
| `unite_naked_full_cache` | boolean | Use same cache for full and naked domains |
| `comply_vary` | boolean | Comply with Vary response header |

---

## TTL Settings

Control TTL conflict resolution (part of main cache settings under `ttl`):

| Field | Type | Description |
|-------|------|-------------|
| `use_shortest_caching` | boolean | Use shortest TTL on conflict (default: longest) |
| `prefer_last_modified` | boolean | Prefer Last-Modified over eTag |

---

## Error Handling

| HTTP Code | Meaning |
|-----------|---------|
| 200 | Success |
| 400 | Bad Request |
| 401 | Unauthorized (invalid API credentials) |
| 404 | Not Found (site or rule doesn't exist) |
| 405 | Rule cannot be deleted |
| 406 | Invalid Input (invalid filter syntax, missing fields) |
| 429 | Rate Limited |
| 500 | Internal Server Error |

### Error 9415 "Operation not allowed"

The API key authenticated but the operation was rejected. Common causes:
1. **Wrong Bitwarden project**: Using `hermes` instead of `hermes-aws`
2. **API key lacks write permission**: Service account needs appropriate permissions in Imperva portal

---

## Pitfalls

- **Flat JSON only**: All request bodies use flat JSON — no `{"data": {...}}` wrapper anywhere in the Cache API.
- **PUT cache settings is partial**: Only fields in the body are modified; omitted fields retain their current values. No special header needed.
- **PUT cache rules needs FULL object**: Despite API spec saying "partial", cache rule PUT requires the complete rule object. Omitting fields causes `{"res": 2, "res_message": "Invalid input"}`. Always GET the rule first, modify, then PUT the full object.
- **Force-Risky-Operation header for rule PUT**: Cache rule PUT operations return HTTP 406 without `Force-Risky-Operation: true` header. Settings PUT does not need this header.
- **Response format is legacy**: Uses `{"res": 0, "res_message": "OK"}` envelope, not `{"value": ..., "isError": false}` like other Imperva APIs.
- **Cache rule field names use camelCase in response**: The API returns `disabledByCacheMode` (camelCase), not `disabled_by_cache_mode` (snake_case) as shown in the OpenAPI spec.
- **Cache rule ID field is `rule_id` not `id`**: POST response returns `{"rule_id": N}`, and GET response includes `rule_id` field.
- **Empty rule list is not an empty array**: When no rules exist, GET returns `{"res": 0, "debug_info": {"Site has no Cache rules": "..."}}` — not `[]` or `{"value": []}`.
- **DELETE restores defaults**: `DELETE /sites/{siteId}/settings/cache` resets ALL cache settings to defaults — use with caution.
- **Cache rules need filter**: Every cache rule requires a `filter` field. Use an empty string `""` for rules that should always match.
- **TTL only for specific actions**: The `ttl` field is only relevant for `HTTP_CACHE_MAKE_STATIC` and `HTTP_CACHE_CLIENT_CACHE_CTL` actions.
- **Ignored params format**: Use `["*"]` (array with single asterisk string) to ignore all parameters.
- **Inline Python fails**: `bws run -- python3 -c "..."` fails for complex Python due to shell escaping. Always write a script file first.
- **Cleanup**: Delete temporary script files from `/tmp/` after use.

---

## Tips

- Always GET current settings before modifying to understand the current state.
- Use the `sections` query param to reduce response size when you only need specific sections.
- Test cache rules in a staging environment before applying to production.
- For cache purge, use specific URL patterns to avoid purging more than intended.
- The `Force-Risky-Operation: true` header may be required for certain PUT operations that change cache behavior significantly.

---

## Related Skills

- `imperva-cwaf-api-manual`: Full API specification reference in `api-spec/cache-api.yaml`
- `imperva-cwaf-get-site-detail`: Get site IDs and current configuration
- `imperva-cwaf-custom-rule`: Manage WAF custom rules (separate from cache rules)
- `imperva-cwaf-policy-management`: Manage WAF policies (ACL, Whitelist, etc.)
- `imperva-cwaf-status-check`: Check Imperva service status
