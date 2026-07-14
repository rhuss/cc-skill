---
name: "docs:changelog"
description: "Generate a changelog entry from recent git commits. Use when preparing a release or documenting what changed between versions."
argument-hint: "<from-tag> [<to-tag>]"
user-invocable: true
---

# Changelog Generator

Generate a formatted changelog entry from git commit history between two tags.

## Steps

### Step 1: Determine Range

If only `from-tag` is provided, use `HEAD` as the end point. If both tags are provided, generate the changelog for commits between them.

```bash
git log ${from_tag}..${to_tag} --oneline --no-merges
```

### Step 2: Categorize Commits

Group commits by type using conventional commit prefixes:
- `feat:` -> Features
- `fix:` -> Bug Fixes
- `docs:` -> Documentation
- `refactor:` -> Refactoring
- `test:` -> Tests
- `chore:` -> Maintenance

Commits without a recognized prefix go into "Other Changes".

### Step 3: Format Changelog

Output in Keep a Changelog format:

```markdown
## [version] - YYYY-MM-DD

### Features
- Description (commit-hash)

### Bug Fixes
- Description (commit-hash)

### Documentation
- Description (commit-hash)
```

### Step 4: Check for Breaking Changes

Search commit messages and bodies for "BREAKING CHANGE:" or commits with `!` after the type prefix. If found, add a "Breaking Changes" section at the top of the changelog entry.

```bash
git log ${from_tag}..${to_tag} --grep="BREAKING CHANGE" --format="%h %s"
```
