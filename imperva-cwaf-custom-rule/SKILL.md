---
name: imperva-cwaf-custom-rule
description: Create, manage, update, and delete Imperva Cloud WAF custom rules via the API.
category: imperva-cwaf
version: 2.2.0
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

> Before creating any custom rules, review the best practice:
> `~/myai/second-brain/20-Cybersecurity/Imperva-CWAF/Best-Practice-Configuration.md`
> Every time a new site is onboarded, create reputation rules + bot management rules per best practice

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

### List/Update/Delete Rules by Name Pattern (⚠️ DESTRUCTIVE for delete — Always Confirm First)

**MANDATORY workflow for delete — never skip the confirmation step.**

Step 1: **List rules with name filter to find candidates:**

```bash
CAID=<caid> SITE_ID=<id> FILTER_NAME=<name> bws run --project-id <bw_id> -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-custom-rule/scripts/list-rules.sh
```

> Note: `FILTER_NAME` does a case-insensitive substring (contains) match. You must manually verify position.

Step 2: **Filter by name pattern with correct position matching (case insensitive).** All matching is case insensitive. Use exact position logic:

| User says | Match condition | Example match | Example NOT match |
|-----------|----------------|---------------|-------------------|
| "ชื่อขึ้นต้นด้วย X" / "starts with X" | `name.toLowerCase().startsWith("x")` | `Block RU`, `block-api` | `my-block`, `reblock` |
| "ชื่อลงท้ายด้วย X" / "ends with X" | `name.toLowerCase().endsWith("x")` | `test-rule`, `my-rule` | `rule-test`, `rule2` |
| "ชื่อมี X" / "contains X" | `name.toLowerCase().contains("x")` | `my-block-rule`, `reblock`, `test-block` | — |

> ⚠️ **CRITICAL**: "ขึ้นต้นด้วย block" means `name.toLowerCase().startsWith("block")` ONLY.
> `Block RU` ✅ `block-api` ✅ — all match (case insensitive, position 0).
> `my-block` ❌ `reblock` ❌ `test Block rule` ❌ — "block" is not at position 0.

Step 3: **For DELETE — Present the filtered list to the user for explicit approval BEFORE deleting.**

Format:
```
The following N rules match the criteria "starts with 'block'":

  ID       Name           Action    Enabled
  ───────  ─────────────  ────────  ───────
  12345    Block RU       BLOCK     true
  12346    Block CN API   ALERT     true
  ...

⚠️ This will DELETE N rules. This action cannot be undone.
Proceed? (yes/no)
```

Step 4: **Only after user confirms "yes", execute deletions one by one using RULE_ID:**

```bash
SITE_ID=<id> RULE_ID=<id> bws run --project-id <bw_id> -- bash \
  ~/.hermes/skills/imperva-cwaf/imperva-cwaf-custom-rule/scripts/delete-rule.sh
```

Step 5: **Report results** — show ✅ deleted and ❌ failed (with reason).

> **Note**: For UPDATE by name, follow the same list → filter → confirm → execute pattern. Show the matched rules and ask which RULE_ID to update before proceeding.

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
- **⚠️ ALWAYS confirm before deleting rules.** List the matched rules, show count, and get explicit user approval before executing ANY delete. Never batch-delete without confirmation.
- **⚠️ Name pattern matching — respect position, case insensitive.** "Starts with X" means the name begins with X at position 0, case insensitive. `Block RU` ✅ `block-api` ✅ match "starts with block". `my-block` ❌ `reblock` ❌ `test Block rule` ❌ do not match — "block" is not at position 0. `FILTER_NAME` does a contains match, so you must manually verify position after listing.

## Related Skills
- `imperva-cwaf-api-manual`: Rule filter parameters reference
- `imperva-cwaf-policy-management`: Account-level policies
- `imperva-cwaf-get-site-detail`: Get site IDs
