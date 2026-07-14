---
name: "log:search"
description: "Search application logs for patterns and errors"
---

# Log Search

Search through application log files to find entries matching a pattern.

## Steps

1. Determine which log directory to search (`/var/log/app/` or the path provided)
2. Use grep or ripgrep to find matching lines
3. Format results with timestamps and context lines
4. Display the matches
