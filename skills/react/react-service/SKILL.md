---
description: Generate frontend service classes (API client / data access layer) for a React frontend. Use whenever the user mentions a frontend service, API client class, data fetching layer, or service that calls the backend in the React project.
argument-hint: [what the user needs]
---

You're the **/react-service** skill. Translate the user's service request into an enriched delegation to the `react-service` agent.

The user's request: **$ARGUMENTS**

## Step 1: Parse

Extract:
- **Module / feature folder** (Bill, Household, etc.)
- **Service class** — `{Name}Service`
- **Methods needed** — group by area (CRUD, Actions)
- **Models returned** — services return `Model.fromApi(...)`
- **Backend endpoints**

## Step 2: Inspect

```bash
ls src/modules/{Module}/ 2>/dev/null || echo "MODULE_MISSING"
ls src/modules/{Module}/services/ 2>/dev/null
ls src/modules/{Module}/models/ 2>/dev/null
ls src/modules/{Module}/types/ 2>/dev/null
```

## Step 3: Resolve Ambiguity

- Models missing → suggest `/react-model` first
- Types missing → create `Create*Payload`, `Update*Payload`, `*Response` in same pass
- Existing service → confirm: add methods or replace?

## Step 4: Build Context Blob

```
Context for react-service agent:
- Module: {Module}
- Class: {Name}Service (static methods)
- Path: src/modules/{Module}/services/{Name}Service.ts
- Models returned: [Bill, BillMember]
- Type imports: [BillListResponse, CreateBillPayload, ...]
- Method groups:
    CRUD: [list, get, create, update, delete]
    Actions: [markPaid, skip]
- Backend endpoints: [GET /api/v1/bills, POST /api/v1/bills, ...]
- HTTP client: project convention (discover from siblings)
- Existing siblings: [BillService.ts]
```

## Step 5: Delegate

Task tool, `subagent_type: "bench:react-service"`, pass the blob.

## Step 6: Synthesize

> "Created `src/modules/Bill/services/BillService.ts`. Static methods grouped by CRUD + Actions. All return `Bill.fromApi()` instances. Suggested follow-up: wrap in `useBills` hook (TanStack Query)."

## When to Ask vs Assume

- Returns model instances → always (`Model.fromApi(...)`)
- Static methods vs class instances → match siblings
- HTTP client → follow project convention
