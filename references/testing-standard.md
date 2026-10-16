# Imperva CWAF Skill Testing Standard

This document defines the **mandatory testing procedure** for all `imperva-cwaf` skills after any modification. Follow this standard to catch errors before they reach production.

## Why This Exists

Skills that look correct on paper can fail due to:
- Wrong path references (templates/ vs scripts/)
- Missing headers (Force-Risky-Operation)
- Missing parameters (RULE_ENABLED in create)
- Naming mismatches between SKILL.md and actual script files
- API behavior changes (GET single rule returning 9411)

**Never assume a skill works from reading code alone. Always test through `bws run` against the real API.**

## Test Environment

| Value | Source |
|-------|--------|
| `SITE_ID` | Retrive from argument |
| `CAID` | Retrieve from argument |
| Credentials | `bws run` |

## Test Procedure

### 0. Pre-flight Checks

Before running any API tests, verify the skill structure:

```bash
# 1. Verify all scripts have executable permission
find ~/.hermes/skills/imperva-cwaf/<skill>/scripts/ -name "*.sh" -exec chmod {} \;

# 2. Verify script headers contain required sections
for f in ~/.hermes/skills/imperva-cwaf/<skill>/scripts/*.sh; do
  echo "=== $f ==="
  head -10 "$f"
done

# 3. Verify SKILL.md references point to existing files
grep -n "scripts/" ~/.hermes/skills/imperva-cwaf/<skill>/SKILL.md
```

### 1. GET Operations (Read-only, Safe)

Start with read-only operations:

```bash
# Test each GET script
SITE_ID=852056322 bws run -- bash get-xxx.sh

# Verify response structure
# - res: 0 means success
# - Expected fields present
```

**What to check:**
- Response is valid JSON
- `res: 0` (not 9411, 9415, or HTTP error)
- Expected data structure matches API spec

### 2. Verbal Walkthrough

Before running write operations, read each script aloud and verify:

1. **Credential source** — Uses `${IMPERVA_API_ID}` / `${IMPERVA_API_KEY}`, never hardcoded
2. **Identifier source** — Uses `${SITE_ID}` / `${RULE_ID}` from env, never hardcoded
3. **Headers** — Has `Accept: application/json`, `Content-Type: application/json` for PUT/POST
4. **Special headers** — `Force-Risky-Operation: true` for cache rule PUT/DELETE
5. **jq usage** — Variables properly quoted with `--arg` / `--argjson`

### 3. Write Operations (Create → Verify → Update → Verify → Delete → Verify)

For each CRUD operation, follow this lifecycle:

#### Create → Verify → Delete Pattern

```bash
# Step 1: Create
SITE_ID=xxxxxx RULE_NAME=TestRule RULE_ACTION=HTTP_CACHE_MAKE_STATIC \
  RULE_FILTER='URL contains ".test"' \
  bws run -- bash create-xxx.sh
# Capture the returned rule_id

# Step 2: Verify creation
SITE_ID=xxxxxxx bws run -- bash get-xxx.sh
# Confirm the new rule exists in the list

# Step 3: Update (if update script exists)
SITE_ID=xxxxxxx RULE_ID=<new_id> RULE_ENABLED=false \
  bws run -- bash update-xxx.sh
# Verify res: 0

# Step 4: Delete
SITE_ID=xxxxxxx RULE_ID=<new_id> \
  bws run -- bash delete-xxx.sh
# Verify res: 0

# Step 5: Verify deletion
SITE_ID=xxxxxxx bws run -- bash get-xxx.sh
# Confirm the rule is gone
```

### 4. Edge Case Testing

Test these scenarios to catch hidden bugs:

| Scenario | What to Test |
|----------|-------------|
| Empty state | Run GET when no rules/configs exist |
| Special characters | Filter with `^`, `$`, `;`, `*` |
| Boolean params | `RULE_ENABLED=false` vs `RULE_ENABLED=true` |
| Optional params | Call script with and without optional env vars |
| Rate limits | If you get HTTP 429, wait and retry |
| WAF blocks | If errorCode 15, retry with backoff (5s, 15s, 30s, 60s) |

### 5. Cleanup

**Always clean up test artifacts after testing:**

```bash
# Remove any test rules created during testing
SITE_ID=xxxxxxx RULE_ID=<test_rule_id> \
  bws run -- bash delete-xxx.sh
```

### 6. Post-test Verification Checklist

After all tests pass, verify:

- [ ] All scripts at correct path (`scripts/` not `templates/`)
- [ ] SKILL.md references match actual script paths
- [ ] SKILL.md examples work when copied verbatim
- [ ] All parameters in usage examples are documented
- [ ] No templates/ directory exists (deleted after migration)
- [ ] File permissions are correct (readable, scripts executable)
- [ ] No Python scripts remain if they should be bash (or vice versa)

## Common Test Failures & Fixes

| Failure | Likely Cause | Fix |
|---------|-------------|-----|
| `res: 9411` | Wrong API credentials | Check bws project ID |
| `res: 9415` | API key lacks write permission | Use correct bws project |
| HTTP 406 | Missing required fields in PUT body | Include all required fields |
| HTTP 429 | Rate limit | Wait 60s, retry |
| errorCode 15 | WAF blocking | Retry with exponential backoff |
| `res: 0` on GET, rule list empty after create | Rule created but wrong site | Verify SITE_ID |
| Update returns success but no change | Missing env var in update | Check env vars are set |

## Test Result Template

Document test results in this format:

```
## Test Results - <skill-name> - <date>

| # | Function | Result | Notes |
|---|----------|--------|-------|
| 1 | Get settings | ✅ | Returns full object |
| 2 | Update mode | ✅ | Changed to smart, reverted |
| 3 | Create rule | ✅ | rule_id: 144090 |
| 4 | Update rule | ✅ | Disabled then renamed |
| 5 | Delete rule | ✅ | Deleted 144090, 144091 |
| 6 | Purge (pattern) | ✅ | Purged style.css |
| 7 | Purge (all) | ✅ | Full purge |
| 8 | Cleanup | ✅ | All test rules removed |

Overall: 8/8 PASS
```

## Integration with skill-dev-standard.md

This testing standard complements `skill-dev-standard.md`:

1. **Before modifying**: Read both documents
2. **During modification**: Follow `skill-dev-standard.md` for structure
3. **After modification**: Follow this document for testing
4. **Before committing**: Ensure all tests pass and checklist is complete
