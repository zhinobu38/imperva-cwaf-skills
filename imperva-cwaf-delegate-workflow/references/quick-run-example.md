# Quick Run Example

## Example: Full site configuration via delegate_task

This example shows how to run the complete Imperva CWAF configuration workflow using `delegate_task` from a Hermes session.

### User Input (Thai)

> "ตั้งค่า Imperva CWAF ให้ myapp.thtechs.com origin 119.110.254.25 block ประเทศ RU, CN whitelist /api/health /status แล้วก็สร้าง custom rule block bot traffic"

### Phase 1: Status Check + Onboard

```
delegate_task(
    goal="""Check Imperva service status and onboard site.

Step 1 - Check status:
curl -s https://status.imperva.com/api/v2/summary.json
If not operational, STOP and report.

Step 2 - Check if site exists:
curl -s -G "https://api.imperva.com/sites-mgmt/v3/sites?caid=<YOUR_CAID>&names=myapp.thtechs.com" \\
  -H "Accept: application/json" \\
  -H "x-API-Id: 214929" \\
  -H "x-API-Key: 22dc432c-7fb0-4449-9667-cd500aedaf3f"

Step 3 - If not exists, onboard:
curl -X POST "https://api.imperva.com/sites-mgmt/v3/sites/onboard?caid=<YOUR_CAID>" \\
  -H "Accept: application/json" -H "Content-Type: application/json" \\
  -H "x-API-Id: 214929" -H "x-API-Key: 22dc432c-7fb0-4449-9667-cd500aedaf3f" \\
  -d '{"domain":"myapp.thtechs.com","name":"myapp.thtechs.com","servers":["119.110.254.25"],"generateCertificate":true,"type":"CLOUD_WAF"}'

Return SITE_ID clearly.""",
    toolsets=["terminal"]
)
```

### Phase 2: Parallel Configuration

After getting SITE_ID from Phase 1 (e.g., `<EXAMPLE_SITE_ID>`):

```
delegate_task(tasks=[
    # 2a - SSL/TLS/HSTS
    {
        "goal": """Configure SSL + TLS + HSTS for site <EXAMPLE_SITE_ID>.
        ... (see SKILL.md Task 2a template) ...""",
        "toolsets": ["terminal"]
    },
    # 2b - Policies (ACL + Whitelist)
    {
        "goal": """Create ACL policy blocking RU,CN + Whitelist for /api/health,/status for site <EXAMPLE_SITE_ID>.
        ... (see SKILL.md Task 2b template) ...""",
        "toolsets": ["terminal"]
    },
    # 2c - Custom Rules
    {
        "goal": """Create custom rule to block bot traffic for site <EXAMPLE_SITE_ID>.
        Rule filter: UserAgent contains "bot" OR UserAgent contains "crawler"
        Action: RULE_ACTION_BLOCK
        ...""",
        "toolsets": ["terminal"]
    }
])
```

### Phase 3: Verification

```
delegate_task(
    goal="""Verify all configurations for site <EXAMPLE_SITE_ID>.
    Check site details, SSL, TLS/HSTS, policies, and custom rules.
    Report summary table.""",
    toolsets=["terminal"]
)
```

---

## Example: Partial Workflow (SSL only for existing site)

```
delegate_task(tasks=[
    {
        "goal": """Enable SSL + configure TLS/HSTS for existing site <EXAMPLE_SITE_ID>.
        CAID: <YOUR_CAID>, API ID: 214929, API Key: 22dc432c-...
        Enable managed cert, set ENHANCED_SECURITY, HSTS max-age 31536000.""",
        "toolsets": ["terminal"]
    }
])
```

## Example: Partial Workflow (Policy only)

```
delegate_task(tasks=[
    {
        "goal": """Create ACL policy blocking RU,CN for site <EXAMPLE_SITE_ID> and apply it.
        CAID: <YOUR_CAID>, API ID: 214929, API Key: 22dc432c-...
        Create → add GEO setting → apply to site.""",
        "toolsets": ["terminal"]
    }
])
```
