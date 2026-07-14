---
name: "deploy:staging"
description: "Deploy a service to the staging environment with health checks and rollback. Use when asked to deploy, push to staging, release to staging, or test a deployment. Do NOT use for production deployments (use deploy:production instead) or for CI/CD pipeline configuration."
argument-hint: "<service-name> [--dry-run] [--skip-tests]"
allowed-tools: ["Bash", "Read"]
user-invocable: true
---

# Deploy to Staging

Deploy a named service to the staging Kubernetes cluster with automated health checks, canary validation, and automatic rollback on failure.

## Why This Skill Exists

Manual staging deployments are error-prone: engineers forget health checks, skip canary validation, or deploy without verifying the image exists. This skill encodes the team's deployment runbook as a repeatable, validated workflow. It catches the mistakes humans make when deploying at 4pm on a Friday.

## Procedure

### Step 1: Validate Prerequisites

Check that the deployment can proceed safely.

1. Verify the service name matches a known service in `deploy/services.yaml`
2. Confirm the container image exists in the registry: `skopeo inspect docker://registry.internal/${service}:${tag}`
3. Check that no other deployment is in progress: `kubectl get deploy ${service} -o jsonpath='{.metadata.annotations.deploy-lock}'`

If `--dry-run` is set, print what would happen and stop after this step.

**Common mistake**: Running `deploy:staging` when the image hasn't been pushed yet. The skill checks the registry first to avoid a `ImagePullBackOff` loop that takes 5 minutes to surface.

### Step 2: Run Pre-deploy Tests

Unless `--skip-tests` is passed:

```bash
./scripts/pre-deploy-check.sh ${service}
```

This runs integration tests against the staging database. If tests fail, stop and report which tests failed. Do not proceed to deployment.

**Why not skip tests by default?** The staging database has real-ish data that occasionally exposes bugs not caught by unit tests. Skipping tests saved 3 minutes but cost us a 2-hour debugging session twice last quarter.

### Step 3: Deploy with Canary

Apply the deployment manifest with 10% canary traffic:

```bash
kubectl apply -f deploy/manifests/${service}-canary.yaml
kubectl rollout status deploy/${service}-canary --timeout=120s
```

Wait 60 seconds, then check error rates:

```bash
./scripts/check-canary-metrics.sh ${service} --threshold 0.5
```

If canary error rate exceeds 0.5%, initiate rollback (Step 5).

### Step 4: Promote to Full

If canary passes, promote to full deployment:

```bash
kubectl apply -f deploy/manifests/${service}-full.yaml
kubectl rollout status deploy/${service} --timeout=300s
```

Verify health endpoint returns 200:

```bash
curl -sf https://${service}.staging.internal/healthz || echo "HEALTH_CHECK_FAILED"
```

### Step 5: Rollback (On Failure)

If any step fails after Step 2:

```bash
kubectl rollout undo deploy/${service}
kubectl rollout undo deploy/${service}-canary
```

Report what failed, the last 20 lines of pod logs, and the rollback status.

**Gotcha**: Rollback does not revert database migrations. If Step 2 included a migration, you need to manually revert it. The skill warns about this but cannot automate it safely.

## Error Handling

| Condition | Action |
|-----------|--------|
| Service not in services.yaml | Stop with "Unknown service: ${service}. Available: ..." |
| Image not in registry | Stop with "Image not found. Did you run `make push`?" |
| Deploy lock active | Stop with "Deployment in progress by ${user} since ${time}" |
| Canary error rate > threshold | Auto-rollback, report error rate and sample errors |
| Health check fails after promote | Auto-rollback, report health check response |

## Flags

- `--dry-run`: Validate prerequisites only, do not deploy
- `--skip-tests`: Skip pre-deploy integration tests (use with caution)
