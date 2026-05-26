---
name: "analyze:complexity"
description: "Analyze code complexity metrics for a file or directory. Use when the user asks to 'check complexity', 'measure cyclomatic complexity', 'find complex functions', or 'assess code quality metrics'. Do NOT use for refactoring suggestions (use refactor:suggest) or for test coverage analysis (use test:coverage)."
argument-hint: "<path> [--threshold <number>]"
user-invocable: true
allowed-tools:
  - Read
  - Bash
  - Grep
  - Glob
---

# Code Complexity Analysis

Analyze code complexity metrics for the specified file or directory. Reports cyclomatic complexity, cognitive complexity, and function length for each function found. This is a read-only analysis that does not modify any files.

Higher complexity scores correlate with higher defect rates because complex functions have more execution paths that are harder to test and reason about. Functions above the threshold warrant review for potential simplification.

## Procedure

### Step 1: Resolve Target

Read the path provided by the user. If it's a directory, use Glob to find all source files:

```
Glob: <path>/**/*.{py,js,ts,go,java}
```

If no source files are found, return:

```
**Error**: No supported source files found in `<path>`. Supported: .py, .js, .ts, .go, .java
```

### Step 2: Analyze Each File

For each source file, read it and compute:
- **Cyclomatic complexity**: Count decision points (if, else, for, while, case, catch, &&, ||)
- **Cognitive complexity**: Weight nested conditions more heavily than flat ones, because nesting makes code harder to understand even when the branch count is similar
- **Function length**: Line count per function

The threshold defaults to 10 if not specified. Functions at or above the threshold are flagged.

### Step 3: Produce Report

Format the analysis using this template:

```
## Complexity Report

**Path**: `<path>`
**Files analyzed**: <count>
**Threshold**: <threshold>

### Flagged Functions

| File | Function | Cyclomatic | Cognitive | Lines | 
|------|----------|-----------|-----------|-------|
| <file> | <function> | <cc> | <cog> | <lines> |

### Summary

- Total functions: <count>
- Above threshold: <count> (<percentage>%)
- Highest complexity: <function> in <file> (CC: <value>)
- Average complexity: <value>
```

If no functions exceed the threshold:

```
### Summary

All <count> functions are below the complexity threshold of <threshold>. No action needed.
```
