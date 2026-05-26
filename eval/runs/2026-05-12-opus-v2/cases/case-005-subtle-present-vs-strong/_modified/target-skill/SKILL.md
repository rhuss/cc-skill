---
name: "review:pr"
description: "Review a pull request for code quality, test coverage, and security issues. Use when asked to 'review this PR', 'check this pull request', 'give feedback on changes', or 'review the diff'."
argument-hint: "[PR number or URL]"
user-invocable: true
allowed-tools:
  - Bash
  - Read
  - Grep
  - Glob
---

# Pull Request Review

Review a pull request systematically for code quality, security, testing, and documentation. Produces a structured review with categorized findings.

Do not use this skill for reviewing commits that haven't been submitted as PRs. Use `review:commit` for single commit review instead.

## Procedure

### Step 1: Obtain PR Information

If the user provided a PR number or URL, extract the PR details:

```bash
gh pr view <number> --json title,body,files,additions,deletions,baseRefName,headRefName
```

If no PR was specified, check if there's a current branch with an open PR:

```bash
gh pr view --json number,title 2>/dev/null
```

If no PR is found, report an error and stop.

### Step 2: Fetch the Diff

```bash
gh pr diff <number>
```

Read the full diff. Note files changed, lines added, lines removed.

### Step 3: Analyze Categories

Review the changes across these categories. Each category has specific things to check.

**Code Quality**:
- Naming clarity
- Function complexity (flag functions over 30 lines)
- Code duplication
- Error handling completeness

**Security**:
- Hardcoded secrets or credentials
- SQL injection vectors
- XSS vulnerabilities in templates
- Insecure dependencies

**Testing**:
- Are new functions covered by tests?
- Do test names describe the scenario?
- Are edge cases tested?

**Documentation**:
- Are public APIs documented?
- Is the PR description adequate?
- Do complex changes have inline comments explaining why?

### Step 4: Produce Review

Format findings as:

```
## PR Review: #<number> - <title>

### Summary
<1-2 sentence overview of the changes and overall impression>

### Findings

#### Critical
- <finding with file:line reference>

#### Suggestions
- <finding with file:line reference>

#### Positive
- <things done well>

### Recommendation
<APPROVE / REQUEST_CHANGES / COMMENT>
```

## Error Handling

| Condition | Response |
|-----------|----------|
| No PR found | "No open PR found for the current branch" |
| gh CLI not available | "The gh CLI is required. Install it from https://cli.github.com" |
| PR has no diff | "This PR has no file changes" |

## Notes

If the PR has more than 1000 lines changed, focus the review on the most critical files (those touching security-sensitive paths, API endpoints, or database queries) rather than trying to cover everything. Large PRs are better served by focused review of high-risk areas than shallow review of all changes, because the signal-to-noise ratio drops sharply in large diffs.
