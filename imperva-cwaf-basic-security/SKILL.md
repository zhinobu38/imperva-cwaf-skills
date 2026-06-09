---
name: imperva-cwaf-basic-security
description: Manage Imperva Cloud WAF basic security settings — backdoor protection, DDoS protection, and bot access control.
category: imperva-cwaf
version: 1.0.0
---

# Imperva CWAF Basic Security Skill

Manage basic security settings for a site via the Imperva Cloud WAF API.

## Credential & Identifier Policy (MANDATORY)

| Value | Source | Method |
|-------|--------|--------|
| `IMPERVA_API_ID` | Bitwarden project `hermes-aws` | Only via `bws run --project-id 61c6c700-2d78-4860-b79e-b46200e193e9` |
| `IMPERVA_API_KEY` | Bitwarden project `hermes-aws` | Only via `bws run --project-id 61c6c700-2d78-4860-b79e-b46200e193e9` |
| `SITE_ID` | User / memory / `imperva-cwaf-get-site-detail` skill | Pass as env var |
| `CAID` | User / memory / `imperva-cwaf-get-site-detail` skill | Pass as env var |

- **NEVER** hardcode credentials or identifiers
- bws injects only `IMPERVA_API_ID` + `IMPERVA_API_KEY`

### Correct Usage Pattern

```bash
SITE_ID=852056322 CAID=2429928 \
  bws run --project-id 61c6c700-2d78-4860-b79e-b46200e193e9 \
  -- bash templates/set-backdoor.sh
```

## Shared References

These files are maintained at the `imperva-cwaf/` skill group level and are the
single source of truth for all sub-skills. Do NOT duplicate their content.

| Reference | Description |
|-----------|-------------|
| `../references/skill-dev-standard.md` | Dev standard: template structure, credential rules, known API behaviors, pitfalls |
| `../references/credential-and-identifier-policy.md` | Credential/identifier sourcing rules (Bitwarden bws run) |
| `../references/shell-template-pattern.md` | Shell template patterns (GET→modify→PUT, form-encoded POST, header format) |

## API Endpoints

| Feature | Method | Endpoint |
|---------|--------|----------|
| Get security config | POST | `/api/prov/v1/sites/status` |
| Backdoor / DDoS / Bot control | POST | `/api/prov/v1/sites/configure/security` |
| Bot config (v3 lists) | GET | `/api/prov/v3/sites/{extSiteId}/settings/botConfiguration` |
| Bot config (v3 lists) | POST | `/api/prov/v3/sites/{extSiteId}/settings/botConfiguration` |

Base URL: `https://my.imperva.com`

All v1 POST endpoints use `Content-Type: application/x-www-form-urlencoded`.

---

## Feature 1: Backdoor Protection

### Parameters

| Parameter | Required | Values |
|-----------|----------|--------|
| `rule_id` | ✅ | `api.threats.backdoor` |
| `security_rule_action` | ✅ | `api.threats.action.quarantine_url` \| `api.threats.action.alert` \| `api.threats.action.disabled` |
| `quarantined_urls` | ❌ | Full URL path to remove from quarantine |

### Actions

| Action | Description |
|--------|-------------|
| `api.threats.action.quarantine_url` | Auto-quarantine detected backdoor URLs |
| `api.threats.action.alert` | Alert only, don't block |
| `api.threats.action.disabled` | Disable backdoor protection |

### Usage Examples

```bash
# Enable quarantine mode
SITE_ID=<id> CAID=<caid> ACTION=api.threats.action.quarantine_url \
  bws run ... -- bash templates/set-backdoor.sh

# Alert only
SITE_ID=<id> CAID=<caid> ACTION=api.threats.action.alert \
  bws run ... -- bash templates/set-backdoor.sh

# Disable
SITE_ID=<id> CAID=<caid> ACTION=api.threats.action.disabled \
  bws run ... -- bash templates/set-backdoor.sh

# Remove URL from quarantine
SITE_ID=<id> CAID=<caid> ACTION=api.threats.action.quarantine_url QUARANTINE_URL=/bad.php \
  bws run ... -- bash templates/set-backdoor.sh
```

---

## Feature 2: DDoS Protection

### Parameters

| Parameter | Required | Default | Values |
|-----------|----------|---------|--------|
| `rule_id` | ✅ | — | `api.threats.ddos` |
| `activation_mode` | ❌ | `auto` | `off` \| `auto` \| `on` \| `adaptive` |
| `ddos_traffic_threshold` | ❌ | `750` | 10–10000 (requests/sec) |
| `unknown_clients_challenge` | ❌ | `none` | `none` \| `cookies` \| `javascript` \| `captcha` |
| `block_non_essential_bots` | ❌ | `true` | `true` \| `false` |

Full parameter name for activation_mode is `api.threats.ddos.activation_mode.{value}`.

### Activation Modes

| Mode | Description |
|------|-------------|
| `off` | Disabled even under attack |
| `auto` | Activates automatically when attack suspected |
| `on` | Always enabled |
| `adaptive` | Adaptive threshold based on site traffic |

### Usage Examples

```bash
# Auto mode with defaults
SITE_ID=<id> CAID=<caid> ACTIVATION_MODE=auto \
  bws run ... -- bash templates/set-ddos.sh

# Adaptive with custom threshold
SITE_ID=<id> CAID=<caid> ACTIVATION_MODE=adaptive TRAFFIC_THRESHOLD=1500 \
  bws run ... -- bash templates/set-ddos.sh

# Disable DDoS protection
SITE_ID=<id> CAID=<caid> ACTIVATION_MODE=off \
  bws run ... -- bash templates/set-ddos.sh

# Challenge unknown clients with CAPTCHA
SITE_ID=<id> CAID=<caid> UNKNOWN_CLIENTS_CHALLENGE=captcha \
  bws run ... -- bash templates/set-ddos.sh
```

---

## Feature 3: Bot Access Control

Two API versions are available:

### v1 — Block/Challenge Toggle (simple)

| Parameter | Required | Default | Values |
|-----------|----------|---------|--------|
| `rule_id` | ✅ | — | `api.threats.bot_access_control` |
| `block_bad_bots` | ❌ | `true` | `true` \| `false` |
| `challenge_suspected_bots` | ❌ | `true` | `true` \| `false` |

```bash
# Block bad bots + challenge suspected bots
SITE_ID=<id> CAID=<caid> BLOCK_BAD_BOTS=true CHALLENGE_SUSPECTED_BOTS=true \
  bws run ... -- bash templates/set-bot-control.sh

# Disable bot blocking
SITE_ID=<id> CAID=<caid> BLOCK_BAD_BOTS=false \
  bws run ... -- bash templates/set-bot-control.sh
```

### v3 — Managed Bot Lists (granular)

Use v3 endpoints for fine-grained control over specific bot IDs.

Reference: https://docs.imperva.com/bundle/cloud-application-security/page/settings/client-classification.htm

#### Get current bot config
```bash
SITE_ID=<id> bws run ... -- bash templates/get-bot-config.sh
```

#### Update bot lists
```bash
# Block specific bad bots (by ID)
SITE_ID=<id> MODE=blockbadbots BOT_IDS=6,12,45 \
  bws run ... -- bash templates/update-bot-config.sh

# Cancel specific good bots (remove from allowlist)
SITE_ID=<id> MODE=cancelgoodbots BOT_IDS=3 \
  bws run ... -- bash templates/update-bot-config.sh
```

**Modes:**
- `blockbadbots` — Replace the bad bots block list
- `cancelgoodbots` — Replace the canceled good bots list

---

## Get Current Security Status

```bash
SITE_ID=<id> CAID=<caid> bws run ... -- bash templates/get-security.sh
```

Returns the `security` section from site status, including current configurations for:
- `waf.rules` — all WAF rules (bot_access_control, backdoor, ddos, sql_injection, xss, etc.)
- `waf.acls` — ACL rules
- `ssl` — SSL detection status

---

## Response Structure

v1 POST responses use the standard Imperva result envelope:

```json
{
  "res": 0,
  "res_message": "OK",
  "debug_info": []
}
```

v3 GET bot configuration:

```json
{
  "data": [{
    "badBots": [{"id": 6, "displayName": "BadBot (Scraper)"}],
    "canceledGoodBots": [{"id": 3, "displayName": "CustomBot (Good Bot)"}]
  }]
}
```

Error codes:
| Code | Description |
|------|-------------|
| 9414 | Feature not permitted |
| 9415 | Operation not allowed |
| 2 | Invalid input |

### Fixed Errors
| Error | Code |
|-------|------|
| `{"code": "ERROR_2002", "status": "404"}` | Site not found |
| `{"code": "ERROR_2014", "status": "404"}` | Sub-account not found |

---

## Pitfalls

- **NEVER hardcode credentials** — always via `bws run`
- **NEVER hardcode identifiers** — SITE_ID/CAID from user env var
- **v1 uses form-encoded POST** — not JSON body; use `--data-urlencode`
- **Bot v3 requires full replacement** — GET first, modify the array, then POST the whole object
- **Bot v3 uses POST for update** — not PUT (despite being a full replacement)
- **Bot v3 clear list** — pass empty BOT_IDS to clear (e.g. `BOT_IDS="" MODE=blockbadbots`)
- **DDoS threshold range** — 10–10000 only; values outside this range return error 2
- **DDoS adaptive mode** — requires specific license; returns error 13003 if not available. Use `auto`, `on`, or `off` instead

## Related Skills

- `imperva-cwaf-api-manual`: API specification browser (site_management.yaml)
- `imperva-cwaf-get-site-detail`: Get site IDs and account info
- `imperva-cwaf-policy-management`: WAF policies (ACL, whitelist)
- `imperva-cwaf-custom-rule`: Custom rules management
- `imperva-cwaf-ssl-management`: SSL/TLS certificate and HSTS settings
