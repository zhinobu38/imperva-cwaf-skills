---
name: imperva-cwaf-cache
description: Manage Imperva Cloud WAF cache settings, custom cache rules, client-side caching, response header caching, and cache purging via the API.
category: imperva-cwaf
version: 2.2.0
---

# Imperva CWAF Cache Management

Manage all cache-related settings for Imperva Cloud WAF sites via the Cache API v2.

## Shared References

| Reference | Description |
|-----------|-------------|
| `../references/skill-dev-standard.md` | Dev standard |
| `../references/credential-and-identifier-policy.md` | Credential rules |
| `../references/shell-template-pattern.md` | Shell template patterns |
| `../references/testing-standard.md` | Testing standard (mandatory after any change) |

## Credential & Identifier Policy (MANDATORY)

| Value | Source | Method |
|-------|--------|--------|
| `IMPERVA_API_ID` | Bitwarden project `hermes-aws` | Only via `bws run --project-id 61c6c700-2d78-4860-b79e-b46200e193e9` |
| `IMPERVA_API_KEY` | Bitwarden project `hermes-aws` | Only via `bws run --project-id 61c6c700-2d78-4860-b79e-b46200e193e9` |
| `SITE_ID` | User / memory / get-site-detail | Pass as env var |

**NEVER hardcode credentials or identifiers.**

## ⚡ Best Practice Configuration Reference

> ก่อนตั้งค่า cache ใดๆ ให้อ่าน best practice ก่อน:
> - Quick ref: `../../references/best-practice-config.md`
> - Full detail: `~/myai/second-brain/20-Cybersecurity/Imperva-CWAF/Best-Practice-Configuration.md`

### Cache Mode Best Practice (from config)
- **Static/brochure site** → `Smart Mode` (default)
- **CMS / user transactions** → `Standard Mode`
- ⚠️ ห้ามใช้ Smart Mode กับ user-specific content

### Cache Response Headers Best Practice (from config)
เพิ่ม security headers ที่ origin server มีให้ cache ด้วย:
- `X-Frame-Options`
- `Content-Disposition`
- `Content-Security-Policy`
- `CORS headers`

### Data Leakage Prevention (from config)
- ตรวจสอบ response headers ของ origin server
- ถ้ามี `Server`, `X-Powered-By`, `X-AspNet-version` → สร้าง rule remove ออก

## ⚡ MANDATORY: Use the Scripts

**ALWAYS use the provided scripts. Do NOT write inline curl or Python.**

All scripts at: `~/.hermes/skills/imperva-cwaf/imperva-cwaf-cache/scripts/`

### Get Cache Settings

```bash
SITE_ID=<id> bws run --project-id <bw_id> -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-cache/scripts/get-cache-settings.sh
```

Optional: `SECTIONS=mode,client_side` to filter sections.

### Update Cache Mode

```bash
SITE_ID=<id> MODE_LEVEL=smart bws run --project-id <bw_id> -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-cache/scripts/update-cache-mode.sh
```

### List Cache Rules

```bash
SITE_ID=<id> bws run --project-id <bw_id> -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-cache/scripts/get-cache-rules.sh
```

### Get Single Cache Rule

```bash
SITE_ID=<id> RULE_ID=<id> bws run --project-id <bw_id> -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-cache/scripts/get-cache-rules.sh
# Then filter by rule_id from the list
```

Note: GET single rule by ID may return 9411 (known API limitation). Use list + filter instead.

### Create Cache Rule

```bash
SITE_ID=<id> RULE_NAME=CacheStatic RULE_ACTION=HTTP_CACHE_MAKE_STATIC \
  RULE_FILTER='URL contains ".css"' RULE_TTL=86400 \
  bws run --project-id <bw_id> -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-cache/scripts/create-cache-rule.sh
```

### Update Cache Rule

```bash
# Update any field — set only the fields you want to change
SITE_ID=<id> RULE_ID=<id> RULE_ENABLED=false \
  bws run --project-id <bw_id> -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-cache/scripts/update-cache-rule.sh
```

The script handles GET → modify → PUT automatically.

### Delete Cache Rule

```bash
SITE_ID=<id> RULE_ID=<id> bws run --project-id <bw_id> -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-cache/scripts/delete-cache-rule.sh
```

### Purge Cache

```bash
# Purge specific URL pattern
SITE_ID=<id> URL_PATTERN=style.css bws run --project-id <bw_id> -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-cache/scripts/purge-cache.sh

# Purge all
SITE_ID=<id> bws run --project-id <bw_id> -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-cache/scripts/purge-cache.sh
```

---

## API Endpoints

| Operation | Method | Endpoint |
|-----------|--------|----------|
| Get cache settings | GET | `/sites/{siteId}/settings/cache` |
| Update cache settings | PUT | `/sites/{siteId}/settings/cache` (partial OK) |
| List cache rules | GET | `/sites/{siteId}/settings/cache/rules` |
| Get single rule | GET | `/sites/{siteId}/settings/cache/rules/{ruleId}` |
| Create cache rule | POST | `/sites/{siteId}/settings/cache/rules` |
| Update cache rule | PUT | `/sites/{siteId}/settings/cache/rules/{ruleId}` (full object) |
| Delete cache rule | DELETE | `/sites/{siteId}/settings/cache/rules/{ruleId}` |
| Purge cache | DELETE | `/sites/{siteId}/cache?url_pattern={pattern}` |
| Purge all | DELETE | `/sites/{siteId}/cache` |

**Note:** Cache API v2 does NOT use `?caid=` query parameter (unlike SSL/custom-rule APIs).

## Cache Mode Levels

| Level | Description |
|-------|-------------|
| `disabled` | Turn off all caching |
| `custom_cache_rules_only` | Only cache via custom rules |
| `standard` | Cache per HTTP headers |
| `smart` | Standard + dynamic page profiling |
| `all_resources` | Cache everything |

## Cache Rule Actions

| Action | Description |
|--------|-------------|
| `HTTP_CACHE_MAKE_STATIC` | Always cache |
| `HTTP_CACHE_CLIENT_CACHE_CTL` | Cache on client |
| `HTTP_CACHE_FORCE_UNCACHEABLE` | Never cache |
| `HTTP_CACHE_ADD_TAG` | Tag for purging |
| `HTTP_CACHE_IGNORE_PARAMS` | Ignore query params in cache key |

See `references/cache-rule-actions.md` for full list with parameters.

## Response Format

Legacy envelope: `{"res": 0, "res_message": "OK", "debug_info": {"id-info": "999999"}}`

Empty rule list: `{"res": 0, "debug_info": {"Site has no Cache rules": "..."}}`

## Error Handling

| Code | Meaning |
|------|---------|
| `res: 0` | Success |
| `res: 9411` | Authentication missing or invalid |
| `res: 9415` | Operation not allowed (wrong BW project or API key lacks write) |
| HTTP 401 | Unauthorized siteId |
| HTTP 406 | Invalid input |
| HTTP 429 | Rate limit — retry with backoff |
| errorCode 15 | WAF block — retry with exponential backoff (5s, 15s, 30s, 60s) |

## Pitfalls
- **Flat JSON only** — no `{"data": {...}}` wrapper anywhere
- **PUT cache settings is partial** — only changed fields needed
- **PUT cache rules needs FULL object** — GET first, modify, PUT complete
- **Force-Risky-Operation header** required for rule PUT
- **Cache rule ID field is `rule_id`** not `id`
- **Empty rule list** returns `{"res": 0, "debug_info": {"Site has no Cache rules": "..."}}`
- **GET single rule may return 9411** even when list works — known API limitation, use list + filter by rule_id instead
- **Cache API v2 does NOT need `?caid=`** — unlike SSL/custom-rule APIs
- **WAF intermittent block (errorCode 15)** — retry with exponential backoff before concluding script is wrong
- **No templates/ directory** — all scripts are in `scripts/` only. The `templates/` directory was removed in v2.2.0 to eliminate confusion. Use `scripts/` exclusively.
- **create-cache-rule supports RULE_ENABLED** — pass `RULE_ENABLED=true|false` (default: true)
- **delete-cache-rule needs Force-Risky-Operation** — script includes this header automatically

## Related Skills
- `imperva-cwaf-get-site-detail`: Get site IDs
- `imperva-cwaf-custom-rule`: WAF custom rules (separate from cache rules)
- `imperva-cwaf-policy-management`: WAF policies
