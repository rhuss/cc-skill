---
name: "pr:review"
description: "Review a pull request for code quality, test coverage, and architectural alignment. Use when asked to review a PR, check code quality, provide feedback on changes, or audit a diff. Do NOT use for creating PRs (use pr:create) or for merging (use pr:merge)."
argument-hint: "<pr-number> [--focus security|performance|correctness] [--brief]"
allowed-tools: ["Read", "Bash", "Glob"]
user-invocable: true
---

# Pull Request Review

Perform a structured code review on a GitHub pull request, covering correctness, test coverage, security, performance, and architectural fit.

## Why This Skill Exists

Code reviews catch bugs before they reach production, but review quality varies wildly. Junior reviewers miss security issues; senior reviewers skip test coverage. This skill applies a consistent checklist so nothing falls through the cracks, while leaving subjective design decisions to the human reviewer.

## Procedure

### Step 1: Fetch the Diff

```bash
gh pr diff ${pr_number}
```

Read the diff. If `--brief` is set, summarize the changes in 3-5 sentences and skip to Step 5.

**Gotcha**: Large diffs (>2000 lines) should be reviewed file-by-file. If the diff exceeds this threshold, switch to per-file review mode automatically and note this in the output.

### Step 2: Check for Common Issues

Review each changed file for:

**Correctness**:
- Off-by-one errors in loops and slices
- Nil/null pointer dereference risks
- Resource leaks (unclosed files, connections, channels)
- Race conditions in concurrent code

**Security** (prioritize if `--focus security`):
- SQL injection via string concatenation
- Unsanitized user input in templates or commands
- Hardcoded secrets or credentials
- Missing authentication/authorization checks

**Performance** (prioritize if `--focus performance`):
- N+1 query patterns
- Unbounded collection growth
- Missing pagination on list endpoints
- Expensive operations inside loops

### Step 3: Verify Test Coverage

Check if the PR includes tests for:
- New public functions/methods
- Changed behavior (not just changed code)
- Error paths and edge cases

```bash
gh pr checks ${pr_number}
```

Note any failing CI checks.

### Step 4: Assess Architectural Fit

Compare the changes against:
- Existing patterns in the same package/module
- The project's documented architecture (if available in `docs/` or `ARCHITECTURE.md`)
- Separation of concerns (is business logic leaking into handlers?)

### Step 5: Generate Review

Output a structured review:

```markdown
## PR #${pr_number} Review

### Summary
<2-3 sentence summary of what the PR does>

### Findings

| Severity | File | Line | Issue |
|----------|------|------|-------|
| ...      | ...  | ...  | ...   |

### Test Coverage
<Assessment of test adequacy>

### Recommendation
<APPROVE | REQUEST_CHANGES | COMMENT>
<Brief justification>
```

**Why this format?** The table makes it easy to address findings one by one. The recommendation gives a clear signal. The summary helps other reviewers who arrive late.

## Error Handling

| Condition | Action |
|-----------|--------|
| PR number not found | Stop: "PR #${pr_number} not found. Check the number and repo." |
| No diff available | Stop: "PR has no changes or is already merged." |
| CI checks still running | Note in review: "CI checks in progress, results may change." |
| Diff too large (>2000 lines) | Switch to per-file mode, note in output |

## Known Limitations

- Cannot assess runtime behavior or performance regressions (use profiling tools for that)
- Architecture assessment depends on documented patterns; undocumented conventions may be missed
- Security review is pattern-based, not a substitute for SAST tools like Semgrep or CodeQL
