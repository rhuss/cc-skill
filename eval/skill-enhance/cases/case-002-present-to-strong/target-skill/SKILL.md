---
name: "api:scaffold"
description: "Generate a REST API endpoint with handler, route, and basic tests. Use when adding new API endpoints to the project."
argument-hint: "<resource-name> [--method GET|POST|PUT|DELETE]"
allowed-tools: ["Read", "Write", "Bash"]
user-invocable: true
---

# API Endpoint Scaffolder

Create a new REST API endpoint with handler function, route registration, request/response types, and a basic test file.

## Steps

### Step 1: Detect Project Framework

Read the project's dependency file to determine which web framework is in use:
- Express.js / Fastify / Koa (Node.js)
- Gin / Chi / Echo (Go)
- FastAPI / Flask / Django (Python)

### Step 2: Generate Handler

Create the handler file following the project's existing patterns. Look at existing handlers for:
- File naming conventions
- Import style
- Error handling patterns
- Response format

### Step 3: Register Route

Add the route to the project's router configuration. Match the existing route registration style.

### Step 4: Create Types

Define request and response types/structs for the endpoint.

### Step 5: Generate Test

Create a basic test file with:
- A test for the happy path (200 response)
- A test for invalid input (400 response)
- A test for not found (404 response)

### Step 6: Verify

Run the project's test suite to confirm the new tests pass and nothing is broken.

## Notes

- The generated code follows existing project conventions
- Review the generated handler logic before using in production
- Complex business logic should be added manually after scaffolding
