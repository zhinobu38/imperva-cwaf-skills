# Cache Settings Response Example

Full example response from `GET /sites/{siteId}/settings/cache`:

```json
{
  "mode": {
    "level": "standard",
    "https": "include_html",
    "time": 360
  },
  "key": {
    "unite_naked_full_cache": true,
    "comply_vary": false
  },
  "response": {
    "stale_content": {
      "mode": "adaptive"
    },
    "cache_shield": true,
    "cache_response_header": {
      "mode": "custom",
      "headers": ["Access-Control-Allow-Origin", "Access-Control-Allow-Methods"]
    },
    "tag_response_header": "Some-Header-Name",
    "cache_empty_responses": true,
    "cache_300x": true,
    "cache_http_10_responses": false,
    "cache_404": {
      "enabled": false,
      "time": 0
    }
  },
  "ttl": {
    "use_shortest_caching": true,
    "prefer_last_modified": false
  },
  "client_side": {
    "enable_client_side_caching": true,
    "comply_no_cache": false,
    "send_age_header": false
  }
}
```

## Cache Rule Response Example

Example response from `GET /sites/{siteId}/settings/cache/rules/{ruleId}`:

```json
{
  "rule_id": 12345,
  "name": "Cache Static Assets",
  "action": "HTTP_CACHE_MAKE_STATIC",
  "enabled": true,
  "filter": "URL contains \".css\"",
  "ttl": 86400,
  "disabled_by_cache_mode": false
}
```

## Update Request Examples

### Change cache mode to smart
```json
{
  "mode": {
    "level": "smart"
  }
}
```

### Enable client-side caching only
```json
{
  "client_side": {
    "enable_client_side_caching": true,
    "comply_no_cache": false,
    "send_age_header": true
  }
}
```

### Set custom response headers to cache
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

### Enable stale content with custom TTL
```json
{
  "response": {
    "stale_content": {
      "mode": "custom",
      "time": 7200
    }
  }
}
```

### Disable caching entirely
```json
{
  "mode": {
    "level": "disabled"
  }
}
```
