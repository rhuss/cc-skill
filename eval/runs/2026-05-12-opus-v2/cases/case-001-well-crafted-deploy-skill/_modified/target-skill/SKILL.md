---
name: "deploy:release"
description: "Deploy a release to staging or production environments. Use when the user asks to 'deploy', 'release', 'push to staging', 'ship to prod', or 'promote a build'. Do NOT use for rollbacks (use deploy:rollback), CI pipeline configuration (use ci:config), or container image builds (use build:image)."
argument-hint: "<environment> [--version <tag>] [--dry-run]"
user-invocable: true
allowed-tools:
  - Bash
  - Read
  - Write
  - Glob
---

# Release Deployment

Deploy a versioned release to the specified target environment. This skill handles the full deployment lifecycle: validation, planning, approval, and execution. It supports both staging and production with environment-specific safeguards.

Production deployments require explicit user approval because they affect live traffic and are difficult to reverse quickly. Staging deployments proceed automatically after validation because they only affect internal testing.

## Procedure

### Step 1: Parse Arguments

Extract from the user's input:
- **environment** (required): `staging` or `production`
- **version** (optional): Git tag or SHA to deploy. Defaults to latest tag on main.
- **dry-run** (optional): If `--dry-run`, show the deployment plan without executing.

If environment is missing, return this error and stop:

```
**Error**: No target environment specified. Usage: `/deploy:release staging` or `/deploy:release production [--version v1.2.3]`
```

If the environment is not `staging` or `production`, return:

```
**Error**: Unknown environment `<env>`. Supported environments: staging, production.
```

### Step 2: Validate Preconditions

Run these checks in order. Stop at the first failure.

```bash
# Check current branch
git rev-parse --abbrev-ref HEAD
```

The branch must be `main`. Deploying from feature branches risks shipping incomplete work because feature branches may have commits that haven't passed full CI.

```bash
# Check for uncommitted changes
git status --porcelain
```

Must be clean. Uncommitted changes would not be included in the deployment artifact, causing a mismatch between what was tested and what ships.

```bash
# Verify the version tag exists
git tag -l "<version>"
```

If version was specified but the tag doesn't exist, return:

```
**Error**: Tag `<version>` not found. Run `git tag -l` to see available tags.
```

### Step 3: Build Deployment Plan

Read the environment configuration:

```bash
cat deploy/environments/<environment>.yaml
```

If the file doesn't exist, return:

```
**Error**: No configuration found for environment `<environment>` at `deploy/environments/<environment>.yaml`.
```

Generate the deployment plan showing:
- Current deployed version (from `deploy/state/<environment>.json`)
- Target version
- Changed services (diff between versions)
- Environment-specific settings (replicas, resource limits)
- Estimated deployment duration

Format the plan using this template:

```
## Deployment Plan

**Environment**: <environment>
**Current version**: <current>
**Target version**: <target>

### Changed Services
| Service | Change | Risk |
|---------|--------|------|
| <name> | <added/modified/removed> | <low/medium/high> |

### Configuration
- Replicas: <count>
- Resources: <cpu/memory limits>
- Health check timeout: <seconds>

**Estimated duration**: <minutes> minutes
```

If `--dry-run` was specified, show the plan and stop. Do not proceed to Step 4.

### Step 4: Request Approval

**For production deployments**: Present the deployment plan and wait for explicit user approval. Do not proceed without a clear "yes" or "approve" from the user. This gate exists because production deployments affect real users and reverting takes 10-15 minutes.

**For staging deployments**: Log the plan and proceed automatically. Staging is a testing environment where failed deployments have minimal impact and can be redeployed immediately.

### Step 5: Execute Deployment

Run the deployment script:

```bash
./deploy/scripts/deploy.sh --env <environment> --version <version> --output deploy/logs/
```

Monitor the output for errors. If the script exits with a non-zero code, report the failure:

```
**Deployment failed**: <error from deploy.sh stderr>
Check `deploy/logs/<timestamp>.log` for details.
```

### Step 6: Verify Health

After deployment completes, run health checks:

```bash
./deploy/scripts/health-check.sh --env <environment> --timeout 120
```

If health checks fail after 120 seconds, report:

```
**Warning**: Health checks failing after deployment. The deployment completed but the service may not be healthy. Check `deploy/logs/health-<timestamp>.log`.
```

If health checks pass, report success:

```
## Deployment Complete

**Environment**: <environment>
**Version**: <version>
**Status**: Healthy
**Duration**: <elapsed> minutes
```

## Error Handling

| Condition | Response |
|-----------|----------|
| No environment argument | Error with usage hint |
| Invalid environment name | Error listing valid environments |
| Not on main branch | Error explaining why main is required |
| Uncommitted changes | Error about artifact mismatch |
| Version tag not found | Error with suggestion to list tags |
| Missing environment config | Error with expected config path |
| Deployment script fails | Error with log path |
| Health checks timeout | Warning with log path |

## Common Mistakes

**Deploying a hotfix from a feature branch**: Even if the fix is urgent, merge to main first and deploy from there. Direct feature branch deploys bypass CI validation and the deployment state tracker loses sync, making the next deployment from main show phantom diffs.

**Skipping the dry-run for production**: Always run `--dry-run` first for production. The plan reveals changed services and risk levels that aren't obvious from the git diff alone, because environment-specific config overlays can change behavior.

**Ignoring health check warnings**: A successful deployment with failing health checks means the new version is running but may be degraded. Don't close the deployment ticket until health checks pass, or roll back if they don't stabilize within 5 minutes.
