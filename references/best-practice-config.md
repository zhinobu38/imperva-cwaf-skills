# Imperva CWAF Best Practice Configuration (Quick Ref)

> 📖 **ฉบับเต็ม**: `~/myai/second-brain/20-Cybersecurity/Imperva-CWAF/Best-Practice-Configuration.md`
> ไฟล์นี้เป็น quick reference เท่านั้น — อย่า duplicate content จาก second-brain

## Baseline

| Area | Recommendation |
|------|---------------|
| TLS | Enable + Enhanced Security cipher. ⚠️ เตือน mixed content ก่อน enable |
| Cache Mode | Smart (static/brochure) / Standard (CMS/login/e-commerce) |
| Cache Headers | เพิ่ม X-Frame-Options, Content-Disposition, CSP, CORS headers |
| Error Pages | ตั้งค่า Block & Captcha + Connection Error pages |
| SIEM | Enable log level ตามที่ user confirm |
| Source Restriction | Block non-Imperva IPs ที่ origin firewall |

## Security

| Area | Recommendation |
|------|---------------|
| WAF Signatures | Block all categories. FP concern → Alert → monitor 1-2 weeks → Block |
| Reputation Rules | Malicious IP Block (Tor, AnonymousProxy) + High Risk IP Block |
| Form/Login Protection | Client restriction + rate limit (ถ้ามี) |
| Data Leakage | Remove Server, X-Powered-By, X-AspNet-Version headers |
| DDoS | Auto mode + threshold (Imperva default 1,000 RPS, adjust หลังมี traffic 30 วัน) |
| Bot Management | Client Type Restriction per app type (web vs API) |

## Onboard Checklist (ย่อ)

**Pre:** ระบุ domain, origin IP, app type, CMS/login paths, SIEM, bot sources, traffic volume
**Baseline:** Onboard → TLS → cipher → cache mode → response headers → error pages → SIEM log → source restriction
**Security:** WAF rules → reputation rules → login protection → header cleanup → DDoS → bot rules
**Post:** Verify DNS → verify access → monitor 24-48h → review Alert rules 1-2 weeks

## Log Level Values (for SIEM)

| Value | Meaning |
|-------|---------|
| `full` | WAF raw + access logs |
| `security` | Security events only |
| `none` | No logs |
| `default` | Account default |
