---
name: "api:test"
description: "Run API endpoint tests against a running service. Use when asked to 'test the API', 'check endpoints', 'verify the service is responding', or 'run health checks'. Do NOT use for load testing (use perf:load) or for writing new test files (use test:create)."
argument-hint: "<base-url> [--endpoints <path>]"
user-invocable: true
allowed-tools:
  - Bash
  - Read
  - Glob
---

# API Endpoint Tester

Test API endpoints against a running service and report results. This skill verifies that endpoints respond correctly, checking status codes, response shapes, and timing. It does not modify any service state, only reads endpoint definitions and sends requests.

Endpoint tests run sequentially rather than in parallel because response times are meaningful and concurrent requests can skew timing measurements on shared services.

## Procedure

### Step 1: Resolve Configuration

Parse the user's input for:
- **base-url** (required): The service base URL (e.g., `http://localhost:8080`)
- **endpoints** (optional): Path to an endpoints definition file. Defaults to `endpoints.yaml` in the current directory.

If no endpoints file can be found, return:

```
**Error**: No endpoints file found. Provide one with `--endpoints <path>` or create `endpoints.yaml` in the current directory.
```

### Step 2: Load Endpoints

Read the endpoints file. Expected format:

```yaml
endpoints:
  - path: /health
    method: GET
    expected_status: 200
  - path: /api/v1/users
    method: GET
    expected_status: 200
    expected_fields: ["id", "name", "email"]
```

If the file is not valid YAML, return an error with the parse failure details and stop.

### Step 3: Execute Tests

For each endpoint:

```bash
curl -s -o /dev/null -w '%{http_code} %{time_total}' -X <method> <base-url><path>
```

Record the status code and response time. If `expected_fields` is defined, also capture the response body and verify the fields exist.

A common mistake is treating any non-200 response as a failure. Some endpoints legitimately return 201 (created), 204 (no content), or 301 (redirect). Always compare against `expected_status`, not a hardcoded 200.

### Step 4: Validate Responses

For each test result, check:
- Status code matches `expected_status`
- Response time is under 5 seconds (configurable per endpoint with `max_time_s`)
- If `expected_fields` defined, all fields present in the JSON response

If the response is not valid JSON when `expected_fields` is set, mark the test as failed with "Response is not valid JSON" rather than crashing on parse.

### Step 5: Report Results

Format using this template:

```
## API Test Results

**Base URL**: `<base-url>`
**Endpoints tested**: <count>
**Passed**: <count>
**Failed**: <count>

| Endpoint | Method | Expected | Got | Time | Status |
|----------|--------|----------|-----|------|--------|
| /health | GET | 200 | 200 | 0.05s | PASS |
| /api/v1/users | GET | 200 | 500 | 1.2s | FAIL |

### Failures
- `GET /api/v1/users`: Expected status 200 but got 500. Response: `{"error": "db connection timeout"}`
```

Example of a passing run with 3 endpoints:

```
## API Test Results

**Base URL**: `http://localhost:8080`
**Endpoints tested**: 3
**Passed**: 3
**Failed**: 0

| Endpoint | Method | Expected | Got | Time | Status |
|----------|--------|----------|-----|------|--------|
| /health | GET | 200 | 200 | 0.02s | PASS |
| /api/v1/users | GET | 200 | 200 | 0.15s | PASS |
| /api/v1/config | GET | 200 | 200 | 0.08s | PASS |

All endpoints responding correctly.
```

## Error Handling

| Condition | Response |
|-----------|----------|
| No base-url provided | Error with usage hint |
| Endpoints file not found | Error with path suggestion |
| Endpoints file not valid YAML | Error with parse details |
| Connection refused | Report per-endpoint: "Connection refused at `<url>`" |
| DNS resolution failure | Report: "Cannot resolve hostname `<host>`" |
| Timeout (>30s) | Report per-endpoint: "Request timed out after 30s" |
| Non-JSON response when fields expected | Mark as FAIL: "Response is not valid JSON" |
