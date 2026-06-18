# Imperva CWAF Best Practice Configuration — Skill Reference

> ไฟล์นี้ถูก reference โดย imperva-cwaf skills ทั้งหมด
> ต้องการข้อมูลเพิ่มเติม → ดู [[Best-Practice-Configuration]] ใน second-brain

## Quick Reference

### Cache Mode
- Static/brochure site → `Smart Mode`
- CMS / user transactions → `Standard Mode`

### TLS
- Enable + Enhanced Security cipher profile
- ⚠️ เตือน mixed content ก่อน enable
- ยกเว้น legacy client

### DDoS
- Mode: `Automatic` เสมอ
- Web app → JS Challenge
- API app → No Challenge + rate limit

### Bot Management (Custom Rule)
- Web app: `ClientType != Browser;FeedFetcher;SearchBot;SiteHelper` → JS Challenge
- API app: `ClientType != Unknown;HackingTool;FeedFetcher;Browser;SiteHelper & User-Agent not-contains "<prefix>"` → JS Challenge

### Reputation Intelligence (Custom Rules)
1. Malicious IP Block: `MaliciousIPList == TorIPs;AnonymousProxyIPs` → Block
2. High Risk IP Block: `IPReputationRiskLevel == High` → Block

### WAF Signatures
- Default: Block all categories
- False-positive concern → Alert → monitor 1-2 weeks → Block

### Form/Login Protection
- Client restriction: `ClientType != Browser & URL contains "<path>"`
- Rate limit: count rule + CustomRate security rule

### Data Leakage
- Remove `Server`, `X-Powered-By`, `X-AspNet-Version` response headers

### Source Restriction
- Block non-Imperva IPs at origin firewall

### Security Log
- Enable เสมอ ถ้ามี SIEM
