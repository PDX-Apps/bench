---
description: Generate frontend service classes (API client / data access layer) for a Vue 3 frontend. Use whenever the user mentions a frontend service, API client class, data fetching layer, or service that calls the backend in the frontend project.
argument-hint: [what the user needs]
---

You're the **/vue-service** skill. Translate the user's service request into an enriched delegation to the `vue-service` agent.

The user's request: **$ARGUMENTS**

## Step 1: Parse

Extract:
- **Module / feature folder** (Bill, Household, etc.)
- **Service class** — `{Name}Service`
- **Methods needed** — grouped by area (CRUD, Actions, queries)
- **Models returned** — services should return mapped model instances (`Model.fromApi(...)`)
- **Backend endpoints** the methods call

## Step 2: Inspect

```bash
ls src/modules/{Module}/ 2>/dev/null || ls src/features/{Module}/ 2>/dev/null || echo "FEATURE_DIR_UNKNOWN"
ls src/modules/{Module}/services/ 2>/dev/null
ls src/modules/{Module}/models/ 2>/dev/null
ls src/modules/{Module}/types/ 2>/dev/null
```

## Step 3: Resolve Ambiguity

- Models missing → flag: "Service returns `Bill` instances but model doesn't exist. Generate `/vue-model` first?"
- Types missing → suggest creating `Create*Payload`, `Update*Payload`, `*Response` in same pass
- Existing service → confirm: add methods or replace?

## Step 4: Build Context Blob

```
Context for vue-service agent:
- Module: {Module}
- Class: {Name}Service
- Path: src/modules/{Module}/services/{Name}Service.ts
- Models returned: [Bill, BillMember]
- Type imports: [BillListResponse, CreateBillPayload, ...]
- Method groups:
    CRUD: [list, get, create, update, delete]
    Actions: [markPaid, skip]
- Backend endpoints: [GET /api/v1/bills, POST /api/v1/bills, ...]
- HTTP client: project convention (discover from sibling services)
- Existing siblings: [BillService.ts, HouseholdService.ts]
```

## Step 5: Delegate

Task tool, `subagent_type: "vue-service"`, pass the blob.

## Step 6: Synthesize

> "Created `src/modules/Bill/services/BillService.ts`. Methods grouped by CRUD + Actions. All return `Bill.fromApi()` instances."

## When to Ask vs Assume

- Always returns model instances (`Model.fromApi(...)`) → never raw data
- Method grouping with `// ====` separators → always
- HTTP client / auth handling → follow project conventions
