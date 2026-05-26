---
name: "text:count"
description: "Count words, lines, and characters in a file. Use when the user asks to count words, get line counts, check file length, or measure text size. Do NOT use for code analysis, complexity metrics, or content summarization."
argument-hint: "<file-path>"
user-invocable: true
---

# Word Counter

Count words, lines, and characters in the specified file.

Read the file at the provided path. Count:
- **Lines**: split by newline
- **Words**: split by whitespace (consecutive whitespace counts as one delimiter)
- **Characters**: total length including whitespace

If the file is binary or unreadable, tell the user the file cannot be counted as text rather than reporting garbled numbers.

Report the counts in this exact format:

```
**File**: `<path>`
- Lines: <n>
- Words: <n>
- Characters: <n>
```

Example for a 3-line README:

```
**File**: `README.md`
- Lines: 3
- Words: 12
- Characters: 87
```

If the file does not exist, tell the user.
