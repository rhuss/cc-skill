---
name: "logs:analyze"
description: "Analyze log files"
user-invocable: true
---

# Log Analyzer

Analyze log files for errors and warnings. Produces a summary report.

## Steps

1. Read the log file specified by the user.

2. Parse each line looking for ERROR, WARN, and FATAL level entries.

3. Group entries by category (error type, source component).

4. Generate a summary:

```
## Log Analysis

**File**: `<path>`
**Total lines**: <count>
**Errors**: <count>
**Warnings**: <count>

### Top Error Types
| Error | Count | First Seen |
|-------|-------|------------|
| <type> | <n> | <timestamp> |
```

5. If there are more than 100 errors, suggest looking at the most recent ones first.
