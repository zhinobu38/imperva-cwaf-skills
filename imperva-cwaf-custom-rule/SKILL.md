---
name: imperva-cwaf-custom-rule
description: Create, manage, update, and delete Imperva Cloud WAF custom rules via the API.
category: imperva-cwaf
version: 2.1.0
---

# Imperva CWAF Custom Rule

Create, update, delete, and manage custom rules in Imperva Cloud WAF via the API.

## Shared References

| Reference | Description |
|-----------|-------------|
| `references/rule-filter-summary.md` | Filter parameters & operators reference |

## Credential & Identifier Policy (MANDATORY)

| Value | Source | Method |
|-------|--------|--------|
| `IMPERVA_API_ID` | Bitwarden project `hermes-aws` | Only via `bws run --project-id 61c6c700-2d78-4860-b79e-b46200e193e9` |
| `IMPERVA_API_KEY` | Bitwarden project `hermes-aws` | Only via `bws run --project-id 61c6c700-2d78-4860-b79e-b46200e193e9` |
| `SITE_ID` | User / memory / get-site-detail | Pass as env var |
| `CAID` | User / memory / get-site-detail | Pass as env var |

**NEVER hardcode credentials or identifiers.**

## Best Practice

> ก่อนสร้าง custom rule ใดๆ ให้ดู best practice ก่อน:
> `~/myai/second-brain/20-Cybersecurity/Imperva-CWAF/Best-Practice-Configuration.md`
> ทุกครั้งที่ onboard site ใหม่ ควรสร้าง reputation rules + bot management rules ตาม best practice

## ⚡ MANDATORY: Use the Scripts

**ALWAYS use the provided scripts. Do NOT write inline curl or Python.**

All scripts at:
- `~/.hermes/skills/imperva-cwaf/imperva-cwaf-custom-rule/scripts/`

### List Custom Rules

```bash
CAID=<caid> SITE_ID=<id> bws run --project-id <bw_id> -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-custom-rule/scripts/list-rules.sh
```

Optional filters (env vars):
- `FILTER_NAME` — substring match on rule name (case-insensitive)
- `FILTER_ACTION` — exact match on action (e.g. `RULE_ACTION_BLOCK`)
- `FILTER_ENABLED` — `true` or `false`

```bash
# List only BLOCK rules
CAID=<caid> SITE_ID=<id> FILTER_ACTION=RULE_ACTION_BLOCK bws run --project-id <bw_id> -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-custom-rule/scripts/list-rules.sh

# List disabled rules with name containing "Test"
CAID=<caid> SITE_ID=<id> FILTER_ENABLED=false FILTER_NAME=Test bws run --project-id <bw_id> -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-custom-rule/scripts/list-rules.sh
```

### Create a Custom Rule

```bash
SITE_ID=<id> CAID=<caid> RULE_NAME=BlockRU RULE_ACTION=RULE_ACTION_BLOCK \
  RULE_FILTER='CountryCode == RU' \
  bws run --project-id <bw_id> -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-custom-rule/scripts/create-rule.sh
```

Optional env vars:
- `RULE_ENABLED` — `true` (default) or `false`

Complex filter example:
```bash
SITE_ID=<id> CAID=<caid> RULE_NAME=BlockAPINonTH RULE_ACTION=RULE_ACTION_ALERT \
  RULE_FILTER='URL contains "/api/" & CountryCode != TH' \
  bws run --project-id <bw_id> -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-custom-rule/scripts/create-rule.sh
```

### Edit (Update) a Custom Rule

```bash
SITE_ID=<id> CAID=<caid> RULE_ID=<id> \
  RULE_FILTER='CountryCode != TH;CN;RU' \
  bws run --project-id <bw_id> -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-custom-rule/scripts/edit-rule.sh
```

Only pass the fields you want to change. Unspecified fields keep their current values.

### Delete a Custom Rule

```bash
SITE_ID=<id> RULE_ID=<id> bws run --project-id <bw_id> -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-custom-rule/scripts/delete-rule.sh
```

---

## Rule Actions

| Action | Description |
|--------|-------------|
| `RULE_ACTION_BLOCK` | Block the request |
| `RULE_ACTION_CAPTCHA` | Show CAPTCHA |
| `RULE_ACTION_INTRUSIVE_HTML` | JavaScript challenge |
| `RULE_ACTION_ALERT` | Log only |

## Rule Filter Syntax

- Multi-value: `CountryCode != TH;US;JP` (semicolon-separated)
- Operators: `contains`, `==`, `!=`, `|` (OR), `&` (AND)
- ClientType values are **PascalCase**: `Browser`, `SearchBot`, `Crawler`

## Error 9415 "Operation not allowed"

1. **Wrong Bitwarden project** — using `hermes` instead of `hermes-aws`
2. **API key lacks write permission** — needs "Rules: Write" in Imperva portal

## Pitfalls
- **Shell escaping in filter strings** — filters with `&`, `|`, `"`, or special chars MUST use jq for JSON building, not string interpolation in `-d`. All scripts use `jq -n --arg` to build JSON safely.
- **Flat JSON body** — no `{"data": {...}}` wrapper
- **ClientType is PascalCase** — `Browser` not `browser`
- **JS challenge action** is `RULE_ACTION_INTRUSIVE_HTML` (not `RULE_ACTION_CHALLENGE_JS`)
- **Multi-value matching** uses semicolons: `ClientType != Browser;SearchBot;SiteHelper`
- **Inline Python fails** in `bws run` — always write script file first
- **Edit requires CAID** — even though the PUT endpoint doesn't use CAID in the path, it's needed for the initial GET in edit-rule.sh

## Related Skills
- `imperva-cwaf-api-manual`: Rule filter parameters reference
- `imperva-cwaf-policy-management`: Account-level policies
- `imperva-cwaf-get-site-detail`: Get site IDs
