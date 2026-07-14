---
name: "git:amend"
description: "Amend the last commit with staged changes"
user-invocable: true
---

# Amend Last Commit

Stage current changes and amend them into the most recent commit without changing the commit message.

1. Run `git add -A`
2. Run `git commit --amend --no-edit`
3. Report the updated commit hash
