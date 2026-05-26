---
name: "logs:analyze"
description: "Analyze log files for errors, warnings, and fatal entries, producing a grouped summary report. Use when the user asks to check logs, find errors in a log file, summarize log output, or parse log entries. Do NOT use for real-time log tailing or streaming, application performance monitoring, or structured log querying (e.g., CloudWatch, Datadog). For those, use the appropriate platform tool directly."
argument-hint: "<path-to-log-file>"
user-invocable: true
---

# Log Analyzer

Analyze log files for errors and warnings, producing a grouped summary report. This is a read-only analysis skill with no file modifications, so it runs without approval gates.

## Steps

### Step 1: Locate the Log File

Obtain the log file path from the command argument or conversation context.

**Validation**: Verify the file exists and is non-empty using the Read tool. If the file is not found or empty, report the error and stop.

### Step 2: Read the Log File

Read the log file contents. For files longer than 5,000 lines, read the last 2,000 lines first to focus on recent activity, because recent errors are almost always more actionable than old ones. Note the truncation in the output summary.

### Step 3: Parse Log Entries

Parse each line looking for ERROR, WARN, and FATAL level entries.

Log lines with recognized levels typically follow formats like `[TIMESTAMP] LEVEL message` or `TIMESTAMP LEVEL component - message`, but formats vary. Match level keywords case-insensitively and at word boundaries to avoid false matches (e.g., "WARNING" in a URL path or a variable named `error_count` is not an error entry).

Multiline stack traces belong to the preceding log entry. If a line does not start with a timestamp or recognized level, append it to the previous entry so stack traces are not counted as separate errors.

### Step 4: Group and Summarize

Group entries by category (error type, source component). Produce the summary using this format:

```
## Log Analysis

**File**: `<path>`
**Total lines**: <count>
**Lines analyzed**: <count> (if truncated, note this)
**Errors**: <count>
**Warnings**: <count>
**Fatals**: <count>

### Top Error Types
| Error | Count | First Seen | Last Seen |
|-------|-------|------------|-----------|
| <type> | <n> | <timestamp> | <timestamp> |

### Top Warning Types
| Warning | Count | First Seen |
|---------|-------|------------|
| <type> | <n> | <timestamp> |
```

**Filled example** for a 12,000-line application log:

```
## Log Analysis

**File**: `/var/log/app/server.log`
**Total lines**: 12,000
**Lines analyzed**: 2,000 (last 2,000 of 12,000)
**Errors**: 47
**Warnings**: 132
**Fatals**: 0

### Top Error Types
| Error | Count | First Seen | Last Seen |
|-------|-------|------------|-----------|
| ConnectionTimeout | 31 | 2024-03-15 08:12:03 | 2024-03-15 09:44:18 |
| NullPointerException | 12 | 2024-03-15 08:30:55 | 2024-03-15 09:41:02 |
| FileNotFound | 4 | 2024-03-15 09:15:33 | 2024-03-15 09:38:47 |

### Top Warning Types
| Warning | Count | First Seen |
|---------|-------|------------|
| DeprecatedAPICall | 89 | 2024-03-15 08:00:01 |
| SlowQuery | 43 | 2024-03-15 08:05:22 |
```

### Step 5: Highlight Actionable Patterns

If there are more than 100 errors, recommend focusing on the most recent cluster first, because a burst of recent errors often points to a single root cause while older scattered errors may already be known issues.

If a single error type accounts for more than 50% of all errors, call it out explicitly, as this concentration usually indicates a systemic issue rather than isolated failures.
