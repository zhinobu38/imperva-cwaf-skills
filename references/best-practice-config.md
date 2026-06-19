# Imperva CWAF Best Practice Configuration (Quick Ref)

> 📖 **Full version**: `~/myai/second-brain/20-Cybersecurity/Imperva-CWAF/Best-Practice-Configuration.md`
> This file is a quick reference only — do not duplicate content from second-brain.

## Baseline

| Area | Recommendation |
|------|---------------|
| TLS | Enable + Enhanced Security cipher. ⚠️ Warn about mixed content before enabling |
| Cache Mode | Smart (static/brochure) / Standard (CMS/login/e-commerce) |
| Cache Headers | Add X-Frame-Options, Content-Disposition, CSP, CORS headers |
| Error Pages | Configure Block & Captcha + Connection Error pages |
| SIEM | Enable log level as confirmed by user |
| Source Restriction | Block non-Imperva IPs at origin firewall |

## Security

| Area | Recommendation |
|------|---------------|
| WAF Policy | Ask user: existing or new? → List policies if existing, or create new per best practice |
| WAF Signatures | Block all categories. FP concern → Alert → monitor 1-2 weeks → Block |
| Reputation Rules | Malicious IP Block (Tor, AnonymousProxy) + High Risk IP Block |
| Form/Login Protection | Client restriction + rate limit (if applicable) |
| Data Leakage | Remove Server, X-Powered-By, X-AspNet-Version headers |
| DDoS | Auto mode + threshold (Imperva default 1,000 RPS, adjust after 30 days of traffic) |
| Bot Management | Client Type Restriction per app type (web vs API) |

## Onboard Checklist (Summary)

**Pre:** Identify domain, origin IP, app type, CMS/login paths, WAF policy decision, SIEM, bot sources, traffic volume
**Baseline:** Onboard → TLS → cipher → cache mode → response headers → error pages → SIEM log → source restriction
**Security:** WAF policy → reputation rules → login protection → header cleanup → DDoS → bot rules
**Post:** Verify DNS → verify access → monitor 24-48h → review Alert rules 1-2 weeks

## Log Level Values (for SIEM)

| Value | Meaning |
|-------|---------|
| `full` | WAF raw + access logs |
| `security` | Security events only |
| `none` | No logs |
| `default` | Account default |
