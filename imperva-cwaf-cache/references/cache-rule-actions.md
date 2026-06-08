# Cache Rule Actions Reference

Detailed reference for each cache rule action and its required/optional parameters.

## HTTP_CACHE_MAKE_STATIC

Always cache the resource regardless of HTTP headers.

```json
{
  "name": "Cache Static Assets",
  "action": "HTTP_CACHE_MAKE_STATIC",
  "enabled": true,
  "filter": "URL contains \".css\" | URL contains \".js\" | URL contains \".png\"",
  "ttl": 86400
}
```

Required: `name`, `action`, `enabled`, `filter`
Optional: `ttl` (seconds)

---

## HTTP_CACHE_CLIENT_CACHE_CTL

Cache the resource on the client browser (sets Cache-Control).

```json
{
  "name": "Client Cache Images",
  "action": "HTTP_CACHE_CLIENT_CACHE_CTL",
  "enabled": true,
  "filter": "URL contains \"/images/\"",
  "ttl": 3600
}
```

Required: `name`, `action`, `enabled`, `filter`
Optional: `ttl` (seconds)

---

## HTTP_CACHE_FORCE_UNCACHEABLE

Never cache the resource, even if headers suggest it's cacheable.

```json
{
  "name": "No Cache for API",
  "action": "HTTP_CACHE_FORCE_UNCACHEABLE",
  "enabled": true,
  "filter": "URL contains \"/api/\""
}
```

Required: `name`, `action`, `enabled`, `filter`

---

## HTTP_CACHE_ADD_TAG

Tag resources for later tag-based purging. The tag name is specified in `text`.

```json
{
  "name": "Tag Product Pages",
  "action": "HTTP_CACHE_ADD_TAG",
  "enabled": true,
  "filter": "URL contains \"/products/\"",
  "text": "product-pages"
}
```

Required: `name`, `action`, `enabled`, `filter`, `text` (tag name)

---

## HTTP_CACHE_ENABLE_ASYNC_VALIDATION

Serve stale content when the origin server is unreachable instead of showing an error.

```json
{
  "name": "Async Validation",
  "action": "HTTP_CACHE_ENABLE_ASYNC_VALIDATION",
  "enabled": true,
  "filter": ""
}
```

Required: `name`, `action`, `enabled`, `filter`

---

## HTTP_CACHE_DIFFERENTIATE_SSL

Cache resources separately for HTTP vs HTTPS requests.

```json
{
  "name": "Differentiate SSL",
  "action": "HTTP_CACHE_DIFFERENTIATE_SSL",
  "enabled": true,
  "filter": ""
}
```

Required: `name`, `action`, `enabled`, `filter`

---

## HTTP_CACHE_DIFFERENTIATE_BY_HEADER

Differentiate cache key by a specific header value. Header name in `differentiate_by_value`.

```json
{
  "name": "Diff by Accept-Language",
  "action": "HTTP_CACHE_DIFFERENTIATE_BY_HEADER",
  "enabled": true,
  "filter": "",
  "differentiate_by_value": "Accept-Language"
}
```

Required: `name`, `action`, `enabled`, `filter`, `differentiate_by_value` (header name)

---

## HTTP_CACHE_DIFFERENTIATE_BY_COOKIE

Differentiate cache key by a specific cookie value. Cookie name in `differentiate_by_value`.

```json
{
  "name": "Diff by Session Cookie",
  "action": "HTTP_CACHE_DIFFERENTIATE_BY_COOKIE",
  "enabled": true,
  "filter": "",
  "differentiate_by_value": "session_id"
}
```

Required: `name`, `action`, `enabled`, `filter`, `differentiate_by_value` (cookie name)

---

## HTTP_CACHE_DIFFERENTIATE_BY_GEO

Cache resources separately based on the request's geolocation. Country code header in `differentiate_by_value`.

```json
{
  "name": "Diff by Country",
  "action": "HTTP_CACHE_DIFFERENTIATE_BY_GEO",
  "enabled": true,
  "filter": "",
  "differentiate_by_value": "X-Country-Code"
}
```

Required: `name`, `action`, `enabled`, `filter`, `differentiate_by_value` (geo header name)

---

## HTTP_CACHE_IGNORE_PARAMS

Ignore query parameters in cache key. Parameters to ignore in `ignored_params`.

```json
{
  "name": "Ignore Tracking Params",
  "action": "HTTP_CACHE_IGNORE_PARAMS",
  "enabled": true,
  "filter": "",
  "ignored_params": ["utm_source", "utm_medium", "utm_campaign"]
}
```

To ignore ALL parameters:

```json
{
  "name": "Ignore All Params",
  "action": "HTTP_CACHE_IGNORE_PARAMS",
  "enabled": true,
  "filter": "",
  "ignored_params": ["*"]
}
```

Required: `name`, `action`, `enabled`, `filter`, `ignored_params` (array of strings, use `["*"]` for all)

---

## HTTP_CACHE_ENRICH_CACHE_KEY

Add a text suffix to the cache key. Suffix in `text`.

```json
{
  "name": "Enrich with version",
  "action": "HTTP_CACHE_ENRICH_CACHE_KEY",
  "enabled": true,
  "filter": "URL contains \"/app/\"",
  "text": "v2"
}
```

Required: `name`, `action`, `enabled`, `filter`, `text` (suffix string)

---

## HTTP_CACHE_FORCE_VALIDATION

Force user authentication with the origin server before serving cached content.

```json
{
  "name": "Force Auth Validation",
  "action": "HTTP_CACHE_FORCE_VALIDATION",
  "enabled": true,
  "filter": "URL contains \"/account/\""
}
```

Required: `name`, `action`, `enabled`, `filter`

---

## HTTP_CACHE_IGNORE_AUTH_HEADER

Cache authenticated resources — serve cached content without validating credentials with origin.

```json
{
  "name": "Cache Auth Content",
  "action": "HTTP_CACHE_IGNORE_AUTH_HEADER",
  "enabled": true,
  "filter": "URL contains \"/api/protected/\""
}
```

Required: `name`, `action`, `enabled`, `filter`

---

## Conditional Parameters Summary

| Parameter | Type | Actions |
|-----------|------|---------|
| `ttl` | integer | `HTTP_CACHE_MAKE_STATIC`, `HTTP_CACHE_CLIENT_CACHE_CTL` |
| `text` | string | `HTTP_CACHE_ADD_TAG` (tag name), `HTTP_CACHE_ENRICH_CACHE_KEY` (suffix) |
| `ignored_params` | string[] | `HTTP_CACHE_IGNORE_PARAMS` (use `["*"]` for all) |
| `differentiate_by_value` | string | `HTTP_CACHE_DIFFERENTIATE_BY_HEADER`, `HTTP_CACHE_DIFFERENTIATE_BY_COOKIE`, `HTTP_CACHE_DIFFERENTIATE_BY_GEO` |
