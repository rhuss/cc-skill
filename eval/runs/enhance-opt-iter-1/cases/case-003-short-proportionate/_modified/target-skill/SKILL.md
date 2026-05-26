---
name: "text:count"
description: "Count words, lines, and characters in a file"
user-invocable: true
---

# Word Counter

Count words, lines, and characters in the specified file.

Read the file. Count:
- Lines (split by newline)
- Words (split by whitespace)
- Characters (total length)

Report the counts:

```
**File**: `<path>`
- Lines: <n>
- Words: <n>
- Characters: <n>
```

If the file does not exist, tell the user.
