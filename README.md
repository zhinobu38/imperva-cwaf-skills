# Imperva CWAF Hermes Agent Skills

> Hermes Agent skills for managing Imperva Cloud WAF via API — site management, security policies, SSL/TLS, caching, custom rules, and more.

## Overview

This repository contains a collection of [Hermes Agent](https://hermes-agent.nousresearch.com/docs) skills for automating Imperva Cloud WAF operations. Each skill encapsulates API knowledge, shell scripts, and reference documentation for a specific CWAF domain.

## Skills

| Skill | Description |
|---|---|
| `imperva-cwaf-site-onboard` | Onboard a new website to Imperva Cloud WAF — create site, configure DNS, verify CNAME |
| `imperva-cwaf-get-site-detail` | List and search CWAF sites, view site configuration and status |
| `imperva-cwaf-basic-security` | Manage basic security settings — WAF rules, backdoor protection, DDoS, bot control |
| `imperva-cwaf-policy-management` | Manage WAF policies — create, update, delete, apply policies with exceptions and conditions |
| `imperva-cwaf-custom-rule` | Create, edit, list, and delete custom WAF rules with filter conditions |
| `imperva-cwaf-ssl-management` | Manage SSL certificates and TLS/HSTS settings |
| `imperva-cwaf-cache` | Manage cache settings and custom cache rules, purge cache |
| `imperva-cwaf-lb-delivery` | Manage origin servers, load balancing, delivery mode, image compression, redirection |
| `imperva-cwaf-status-check` | Check operational status of Imperva services |
| `imperva-cwaf-api-manual` | Full API reference — OpenAPI specs, integration guides, rule filter documentation |

## Prerequisites

- [Hermes Agent](https://hermes-agent.nousresearch.com/docs) installed and configured
- Imperva Cloud WAF account with API access
- API credentials: `api_id` and `api_key` (recommend: configured via `bws` or environment variables)
- `curl`, `jq` available on the system

## Installation

### Option 1: Clone into Hermes skills directory

```bash
cd ~/.hermes/skills
git clone https://github.com/zhinobu38/imperva-cwaf-skills.git imperva-cwaf
```

### Option 2: Add as a Git submodule

```bash
cd ~/.hermes/skills
git submodule add https://github.com/zhinobu38/imperva-cwaf-skills.git imperva-cwaf
```

### Option 3: Download a specific release

```bash
# Download the latest beta release
wget https://github.com/zhinobu38/imperva-cwaf-skills/archive/refs/tags/beta-1.0.tar.gz
tar xzf beta-1.0.tar.gz
mv imperva-cwaf-skills-beta-1.0 ~/.hermes/skills/imperva-cwaf
```

## Configuration

Skills use the following credentials (never hardcoded):

- **api_id** / **api_key** — Imperva API credentials
- **CAID** — Customer Account ID (for v1 security APIs)
- **site_id** — Target site ID (per-operation)

Credentials are resolved via `bws` (Bitwarden Secrets Manager) or environment variables. Each skill's `SKILL.md` documents the exact credential requirements.

## Usage

Once installed, Hermes Agent automatically discovers the skills. You can invoke them naturally:

```
"Check the status of my CWAF site www.xxx.com"
"Create a custom WAF rule to block requests from IP 1.2.3.4"
"Onboard example.com to Imperva CWAF"
"Show me all cache rules for my site"
"Update TLS config to use TLS 1.2 only"
```

Each skill contains:
- `SKILL.md` — Trigger conditions, workflow steps, API details
- `scripts/` — Executable shell scripts for API operations
- `references/` — API response examples, parameter tables, error codes

## Skill Development Standards

All skills in this repo follow a shared development standard defined in:
- `references/skill-dev-standard.md` — Skill structure and quality requirements
- `references/testing-standard.md` — Testing and validation guidelines
- `references/credential-and-identifier-policy.md` — Credential handling rules

## API Versions

| API | Base URL | Auth |
|---|---|---|
| v1 (Security) | `my.imperva.com/api/prov/v1` | api_id + api_key + CAID |
| v3 (Site Management) | `my.imperva.com/api/prov/v3` | api_id + api_key |
| v3 (Certificates) | `my.imperva.com/api/certificates-ui/v3` | api_id + api_key |

## Project Structure

```
imperva-cwaf/
├── imperva-cwaf-site-onboard/       # Site onboarding
│   ├── SKILL.md
│   ├── scripts/
│   └── references/
├── imperva-cwaf-get-site-detail/    # Site listing & search
├── imperva-cwaf-basic-security/     # WAF, DDoS, bot, backdoor
├── imperva-cwaf-policy-management/  # Policy CRUD & exceptions
├── imperva-cwaf-custom-rule/        # Custom WAF rules
├── imperva-cwaf-ssl-management/     # SSL/TLS certificates
├── imperva-cwaf-cache/              # Cache rules & purge
├── imperva-cwaf-lb-delivery/        # Load balancing & delivery
├── imperva-cwaf-status-check/       # Service status
├── imperva-cwaf-api-manual/         # Full API reference
│   ├── api-spec/                    # OpenAPI specs
│   └── references/
└── references/                      # Shared standards
    ├── skill-dev-standard.md
    ├── testing-standard.md
    ├── credential-and-identifier-policy.md
    └── shell-template-pattern.md
```

## Versioning

- `beta-1.0` — First consolidated release with all core skills

## License

MIT
