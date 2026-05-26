---
name: "db:migrate"
description: "Run database migrations. Helps with database schema changes."
argument-hint: "[up|down|status] [--target <version>]"
user-invocable: true
allowed-tools:
  - Bash
  - Read
---

# Database Migration

Run database schema migrations for the project. Supports applying migrations (up), reverting migrations (down), and checking current status.

## Procedure

### Step 1: Determine Action

Parse the user's input for:
- **action**: `up` (default), `down`, or `status`
- **target**: specific migration version (optional)

If action is not recognized, show usage and stop.

### Step 2: Check Current State

```bash
./scripts/db-tool.sh status
```

Report the current migration version and any pending migrations.

If the database is unreachable, return:

```
**Error**: Cannot connect to database. Check your DATABASE_URL environment variable.
```

### Step 3: Plan Changes

If action is `status`, report the current state from Step 2 and stop.

For `up` or `down`, generate a migration plan:
- List migrations to be applied or reverted
- Show the SQL for each migration
- Flag any destructive operations (DROP TABLE, DROP COLUMN)

Present the plan to the user and wait for approval before proceeding. Migrations modify the database schema and incorrect migrations can cause data loss, so user review is mandatory.

### Step 4: Execute Migrations

After user approves:

```bash
./scripts/db-tool.sh <action> --target <version>
```

If the migration fails, report the error and the last successful migration version.

### Step 5: Verify

```bash
./scripts/db-tool.sh status
```

Confirm the database is at the expected version. Report success with before/after versions.

## Error Handling

| Condition | Response |
|-----------|----------|
| Unknown action | Show usage |
| Database unreachable | Error with DATABASE_URL hint |
| Migration fails | Error with last good version |
