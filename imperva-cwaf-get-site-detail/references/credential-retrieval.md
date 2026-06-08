# Imperva CWAF — Credential Retrieval

## Rule: ALWAYS use Bitwarden (bws), NEVER local env vars or hardcoded values

API credentials MUST be retrieved from Bitwarden Secrets Manager at runtime.
Do NOT use `$IMPERVA_API_ID` / `$IMPERVA_API_KEY` from the local shell environment.
Do NOT hardcode credentials in scripts, curl commands, or Python code.

### Bitwarden Configuration

- **CLI**: `bws` (Bitwarden Secrets Manager CLI) — installed at `/usr/local/bin/bws`
- **Project ID**: `<BW_PROJECT_ID_READ>`
- **Secret keys**: `IMPERVA_API_ID`, `IMPERVA_API_KEY`
- **Account**: CAID `<YOUR_CAID>` (Mtech Sandbox)

### How to use

`bws run` injects ALL secrets from the project as environment variables using their key names.

**Pattern — write script file, then run via bws:**

```bash
# Step 1: Write your script to a file (no credentials in the file)
# (use write_file tool or cat heredoc)

# Step 2: Execute with credentials injected from Bitwarden
bws run --project-id <BW_PROJECT_ID_READ> -- python3 /tmp/my_script.py
```

### Why not inline in terminal?

Inline Python with secret references in `terminal()` commands gets **blocked by the security filter** when it detects credential-like patterns. Always:
1. Write the script to a file first (no credentials in the file)
2. Run the file via `bws run`

### Troubleshooting

| Error | Meaning | Fix |
|-------|---------|-----|
| `res:9411` / 401 | Credentials invalid or missing permissions | Check Bitwarden secret values; escalate permissions |
| `res:9415` / 403 | Operation not allowed (site NOT_CONFIGURED) | Point DNS to Imperva CNAME first |
