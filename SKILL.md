---
name: imperva-cwaf
description: Imperva Cloud WAF — skill group index. Load this first for any Imperva CWAF task. Provides the full skill map, references, and routing to the correct sub-skill.
---

# Imperva CWAF — Skill Group Index

> **Load this skill first** for any Imperva Cloud WAF task.
> This file is the authoritative map of the entire skill group.
> All paths are relative to `~/.hermes/skills/imperva-cwaf/`.

---

## Skill Map

| # | Skill | What It Does | Path |
|---|-------|-------------|------|
| 1 | **get-site-detail** | List, search, delete CWAF sites | `imperva-cwaf-get-site-detail/` |
| 2 | **site-onboard** | Onboard a new website to CWAF | `imperva-cwaf-site-onboard/` |
| 3 | **basic-security** | Manage basic security settings (backdoor, DDoS, rate limits) | `imperva-cwaf-basic-security/` |
| 4 | **custom-rule** | Create, edit, delete custom WAF rules | `imperva-cwaf-custom-rule/` |
| 5 | **policy-management** | Manage WAF policies (ACL, whitelist, exceptions) | `imperva-cwaf-policy-management/` |
| 6 | **cache** | Manage cache settings, rules, purge | `imperva-cwaf-cache/` |
| 7 | **lb-delivery** | Origin servers, load balancing, delivery settings | `imperva-cwaf-lb-delivery/` |
| 8 | **ssl-management** | SSL certificates, TLS/HSTS settings | `imperva-cwaf-ssl-management/` |
| 9 | **siem-integration** | SIEM log integration (connections, log configs) | `imperva-cwaf-siem-integration/` |
| 10 | **stats-and-visits** | Site statistics, visit logs, IP reputation, session release | `imperva-cwaf-stats-and-visits/` |
| 11 | **status-check** | Check operational status of Imperva services | `imperva-cwaf-status-check/` |
| 12 | **troubleshoot** | Troubleshoot performance and availability issues | `imperva-cwaf-troubleshoot/` |
| 13 | **api-manual** | Browse and search the full Imperva CWAF API spec | `imperva-cwaf-api-manual/` |

---

## Quick Routing

Use this table to find the right skill fast:

| Task | Skill |
|------|-------|
| Find a site ID or CNAME | `get-site-detail` |
| Add a new site to CWAF | `site-onboard` |
| Block/allow an IP, set rate limits | `basic-security` |
| Create a custom WAF rule | `custom-rule` |
| Manage ACL / whitelist / policy exceptions | `policy-management` |
| Configure caching, purge cache | `cache` |
| Set up origin servers, load balancing | `lb-delivery` |
| Upload/manage SSL certs, configure TLS | `ssl-management` |
| Connect SIEM, view log configs | `siem-integration` |
| View stats, visit logs, check IP reputation | `stats-and-visits` |
| Check if Imperva service is up | `status-check` |
| Debug site performance issues | `troubleshoot` |
| Look up API endpoints or spec | `api-manual` |

---

## Shared References

All sub-skill scripts and SKILL.md files reference these:

| Reference | Path | Purpose |
|-----------|------|---------|
| **Skill Dev Standard** | `references/skill-dev-standard.md` | Development standard for all imperva-cwaf skills |
| **Testing Standard** | `references/testing-standard.md` | Mandatory testing procedure after any modification |
| **Best Practice Config** | `references/best-practice-config.md` | Recommended CWAF configuration (referenced by 7+ skills) |
| **API Spec → Skill Mapping** | `imperva-cwaf-api-manual/references/api-spec-to-skill-mapping.md` | Tracks which API spec files map to which skills/scripts |
| **API Spec Overview** | `imperva-cwaf-api-manual/references/api-spec-overview.md` | Overview of all API spec files |

---

## Credential Quick Reference

All skills use the same credential pattern:

| Value | Source |
|-------|--------|
| `IMPERVA_API_ID` | `bws run --project-id 61c6c700-2d78-4860-b79e-b46200e193e9` |
| `IMPERVA_API_KEY` | `bws run --project-id 61c6c700-2d78-4860-b79e-b46200e193e9` |
| `SITE_ID` | User env / memory / `get-site-detail` |
| `CAID` | User env / memory / `get-site-detail` |

See `references/skill-dev-standard.md` for full credential rules.

---

## Development Rules

1. **Language:** All skill content must be in English (see `references/skill-dev-standard.md`).
2. **Mapping:** Every time a skill is created or modified, update `imperva-cwaf-api-manual/references/api-spec-to-skill-mapping.md`.
3. **Testing:** After any modification, follow `references/testing-standard.md`.
4. **Best Practice:** When configuring CWAF settings, consult `references/best-practice-config.md`.
