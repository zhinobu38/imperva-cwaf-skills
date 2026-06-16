# JQ Temp File Technique

When using `bws run -- bash script.sh`, the command passes through a double-shell layer. This mangles inline jq filters that contain double-quotes, special characters, or complex expressions.

## Problem

```bash
# BREAKS through bws run — jq compile error
echo "$RESPONSE" | jq -r "
  \"Timestamp: \(.data[0].timestamp | . / 1000 | strftime(\"%Y-%m-%d %H:%M:%S\"))\"
"
```

## Solution

Write jq filter to a temp file using single-quoted heredoc, then use `-f`:

```bash
# WORKS through bws run
cat > /tmp/format.jq << 'JQEOF'
    "Timestamp: \(.data[0].timestamp | . / 1000 | strftime("%Y-%m-%d %H:%M:%S"))",
    "Account: \(.data[0].accountId)"
JQEOF

echo "$RESPONSE" | jq -r -f /tmp/format.jq
rm -f /tmp/format.jq
```

## Key Rules

1. Use `<< 'JQEOF'` (single-quoted delimiter) — prevents shell variable expansion inside the heredoc
2. Use `jq -r -f /tmp/format.jq` — reads filter from file, avoids shell quoting entirely
3. Clean up with `rm -f /tmp/format.jq` after use
4. This pattern is REQUIRED for any jq filter containing double-quotes, parentheses, or complex expressions when called through `bws run`
