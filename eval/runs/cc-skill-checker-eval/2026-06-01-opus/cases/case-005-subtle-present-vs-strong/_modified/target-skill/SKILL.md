---
name: "test:generate"
description: "Generate unit tests for a source file. Analyzes the code and creates test cases covering public functions, edge cases, and error paths. Use when you need test coverage for new code or when tests are missing."
argument-hint: "<source-file>"
allowed-tools: ["Read", "Write", "Bash"]
user-invocable: true
---

# Test Generator

Generate unit tests for a given source file by analyzing its public interface, control flow, and error handling paths.

## Why This Exists

Writing tests from scratch is tedious and developers skip it. This skill generates a solid starting point that covers the obvious cases, so the developer can focus on the tricky edge cases that require domain knowledge.

## Steps

### Step 1: Analyze the Source File

Read the source file. Identify:
- Public functions and methods
- Input parameter types and ranges
- Return types
- Error conditions (throws, error returns, panics)
- External dependencies (imports, API calls)

### Step 2: Design Test Cases

For each public function, generate test cases for:
- Happy path with typical inputs
- Boundary values (empty string, zero, max int)
- Error cases (nil input, invalid format)
- If the function has side effects, test those separately

### Step 3: Write Tests

Create the test file following project conventions:
- Match the project's test framework (detect from existing tests or config)
- Use the project's assertion style
- Follow the naming convention of existing tests

Write the test file to the standard test location for the language.

### Step 4: Run and Fix

Run the generated tests:

```bash
# Detect and run appropriate test command
```

If any tests fail due to incorrect assumptions, fix them. Report which tests pass and which needed adjustment.

## Tips

- The generated tests are a starting point, not a final product
- Review the generated tests for correctness before committing
- Edge cases that require domain knowledge need manual attention
