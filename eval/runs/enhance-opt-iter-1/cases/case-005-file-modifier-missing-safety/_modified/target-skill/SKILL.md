---
name: "license:insert"
description: "Insert a license header into source files. Use when adding copyright headers to project files."
argument-hint: "<directory> [--license <type>]"
user-invocable: true
allowed-tools:
  - Read
  - Edit
  - Glob
---

# License Header Inserter

Insert a license header at the top of all source files in a directory.

## Procedure

### Step 1: Resolve Inputs

Parse the user's input for:
- **directory** (required): Path to scan for source files
- **license** (optional): License type. Defaults to "Apache-2.0". Supported: Apache-2.0, MIT, GPL-3.0.

If the directory does not exist, return an error and stop.

### Step 2: Find Source Files

Use Glob to find files:

```
Glob: <directory>/**/*.{py,js,ts,go,java,rb,rs}
```

### Step 3: Generate Header

Build the license header text based on the selected license type. Use comment syntax appropriate to the file extension:
- `#` for Python, Ruby
- `//` for JavaScript, TypeScript, Go, Rust, Java

### Step 4: Insert Headers

For each file found in Step 2, read the file and check if it already has a license header (look for "Copyright" or "License" in the first 5 lines).

If no header exists, use the Edit tool to insert the header at the top of the file.

### Step 5: Report

```
## License Headers Inserted

**Directory**: `<path>`
**License**: <type>
**Files processed**: <total>
**Headers added**: <count>
**Already had headers**: <count>
```

## Error Handling

| Condition | Response |
|-----------|----------|
| Directory not found | Error with path |
| Unsupported license type | Error listing supported types |
