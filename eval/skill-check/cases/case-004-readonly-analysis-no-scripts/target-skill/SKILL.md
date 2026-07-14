---
name: "review:dependencies"
description: "Analyze project dependencies for security vulnerabilities, license compliance, and staleness. Use when auditing dependencies, checking for CVEs, reviewing license obligations, or assessing upgrade risk. Not for actually upgrading packages (use update:deps instead)."
allowed-tools: ["Read", "Bash", "Glob"]
user-invocable: true
---

# Dependency Review

Perform a read-only analysis of the project's dependency tree. This skill reads lock files, queries vulnerability databases, and produces a structured report. It does not modify any files.

## Procedure

### Step 1: Identify Package Manager

Detect which package manager the project uses by checking for lock files:

- `package-lock.json` or `yarn.lock` or `pnpm-lock.yaml` -> Node.js
- `Cargo.lock` -> Rust
- `go.sum` -> Go
- `requirements.txt` or `poetry.lock` or `uv.lock` -> Python

If multiple lock files exist, analyze all of them and report separately.

### Step 2: Scan for Vulnerabilities

For each detected ecosystem, run the appropriate audit command:

- Node.js: `npm audit --json` or `yarn audit --json`
- Rust: `cargo audit --json`
- Go: `govulncheck ./...`
- Python: `pip-audit --format json`

Parse the JSON output and extract: package name, installed version, vulnerability ID (CVE), severity, and fixed version (if available).

### Step 3: Check License Compliance

Read the lock file to extract all transitive dependencies and their licenses. Flag any dependency using:
- GPL-3.0 (copyleft, may conflict with proprietary code)
- AGPL-3.0 (network copyleft)
- Unknown or missing license

### Step 4: Assess Staleness

For each direct dependency, compare the installed version against the latest available:

- **Current**: installed version matches latest
- **Minor behind**: patch or minor version available
- **Major behind**: major version available (breaking changes likely)
- **Abandoned**: no release in over 2 years

### Step 5: Generate Report

Output a markdown table with columns:

| Package | Version | Latest | Staleness | Vulnerabilities | License | Action Needed |

Sort by severity: vulnerabilities first, then license issues, then staleness.
