---
description: Generate React frontend model classes (Class + I{Name} interface + fromApi factory) for a React frontend. Use whenever the user mentions a frontend model, TypeScript class wrapping API data, domain object, or .ts model file in the React project.
argument-hint: [what the user needs]
---

You're the **/react-model** skill. Translate the user's model request into an enriched delegation to the `react-model` agent.

The user's request: **$ARGUMENTS**

## Step 1: Parse

Extract:
- **Module** (Bill, Household, etc.)
- **Model name** (PascalCase)
- **Fields** the API returns (matches backend's API Resource shape)
- **Computed getters** (`isOverdue`, `isPaid`)
- **Domain methods** (`canEditBy(user)`)
- **Nested models**

## Step 2: Inspect

```bash
ls src/modules/{Module}/ 2>/dev/null || echo "MODULE_MISSING"
ls src/modules/{Module}/models/ 2>/dev/null
ls src/modules/{Module}/types/ 2>/dev/null
```

## Step 3: Resolve Ambiguity

- Field shape unknown → check backend API Resource (`Modules/{Module}/app/Http/Resources/{Name}Resource.php`)
- Nested models → confirm: generate `BillMember` model too if missing?
- Top-level (User) vs module-local

## Step 4: Build Context Blob

```
Context for react-model agent:
- Module: {Module}
- Model: {Name}
- Path: src/modules/{Module}/models/{Name}.ts
- Interface: I{Name}
- Fields: [id, name, amount, status, members?, createdAt, updatedAt]
- Computed getters: [isPaid, isOverdue, totalApprovedSplit]
- Domain methods: [canEditBy(userId)]
- Static utilities: [calculateTotalAssigned(members)]
- Nested model conversions: members → BillMember instances
- Barrel update: src/modules/{Module}/models/index.ts
- Existing siblings: [BillMember.ts]
```

## Step 5: Delegate

Task tool, `subagent_type: "bench:react-model"`, pass the blob.

## Step 6: Synthesize

> "Created `src/modules/Bill/models/Bill.ts`. Class implements `IBill`. Static `fromApi(this: void, data)` factory. Getters: `isPaid`, `isOverdue`."

## When to Ask vs Assume

- `static fromApi(this: void, ...)` → always (enables `.map(Bill.fromApi)`)
- Class + `I{Name}` interface → always
- Nested model conversion → assume yes when fields contain other models
