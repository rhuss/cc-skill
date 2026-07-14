---
name: "db:migrate"
description: "Run database migrations against the target environment. Use when applying schema changes, running pending migrations, or checking migration status. Do NOT use for seed data insertion or database backups."
argument-hint: "<environment> [--status] [--rollback <N>]"
user-invocable: true
---

# Database Migration Runner

Apply pending database migrations to a target environment (dev, staging, production) using Alembic.

## Procedure

### Step 1: Determine Target Environment

Read the environment argument. Valid values: `dev`, `staging`, `production`.

If `production` is specified, require confirmation via AskUserQuestion before proceeding:
> "You are about to run migrations against PRODUCTION. This cannot be undone automatically. Continue?"

### Step 2: Check Migration Status

```bash
alembic --config config/${env}.ini current
alembic --config config/${env}.ini heads
```

If `--status` flag is set, display current revision and pending migrations, then stop.

### Step 3: Run Pending Migrations

```bash
alembic --config config/${env}.ini upgrade head
```

Report the number of migrations applied and the new current revision.

### Step 4: Verify Schema

Run the schema validation script:

```bash
python scripts/verify_schema.py --env ${env}
```

Report any discrepancies between the expected schema and the actual database state.

If `--rollback <N>` is specified, roll back N migrations instead of applying:

```bash
alembic --config config/${env}.ini downgrade -${N}
```
