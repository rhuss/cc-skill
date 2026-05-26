---
name: "config:validate"
description: "Validate configuration files against a schema. Use when checking config file correctness or verifying required fields."
argument-hint: "<config-path> [--schema <schema-path>]"
user-invocable: true
allowed-tools:
  - Read
  - Bash
  - Glob
---

# Config Validator

Validate a configuration file (YAML or JSON) against its schema. Reports missing fields, type mismatches, and constraint violations.

## Procedure

### Step 1: Resolve Inputs

Parse the user's input for:
- **config-path** (required): Path to the config file
- **schema-path** (optional): Path to the schema file. If not provided, look for a file named `schema.yaml` or `schema.json` in the same directory as the config file.

If the config file does not exist, report an error and stop.
If no schema can be found, report an error and stop.

### Step 2: Load and Parse

Read both files using the Read tool.

Parse the config file as YAML or JSON based on extension. If parsing fails, report the syntax error with line number.

Parse the schema file the same way.

### Step 3: Validate

Compare the config against the schema:
- Check all required fields are present
- Check field types match (string, number, boolean, array, object)
- Check enum constraints (field value must be one of the allowed values)
- Check nested objects recursively

### Step 4: Report

Format the results:

```
## Validation Report

**Config**: `<path>`
**Schema**: `<path>`
**Status**: PASS | FAIL

### Issues Found
| Field | Issue | Expected | Got |
|-------|-------|----------|-----|
| <field.path> | missing | required | - |
| <field.path> | type mismatch | string | number |
```

If no issues found, report PASS with the field count.

## Error Handling

| Condition | Response |
|-----------|----------|
| Config file not found | Show error |
| Schema file not found | Show error |
| Parse error | Show error with line number |
