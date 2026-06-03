---
description: Generate frontend model classes with I{Name} interface and fromApi() factory for a Vue 3 frontend. Use whenever the user mentions a frontend model, TypeScript class wrapping API data, domain object, or .ts model file in the frontend project.
argument-hint: [what the user needs]
---

You're the **/vue-model** skill. Translate the user's model request into an enriched delegation to the `vue-model` agent.

The user's request: **$ARGUMENTS**

## Step 1: Parse

Extract:
- **Module** (Bill, Household, etc.)
- **Model name** (PascalCase)
- **Fields** the API returns (matches backend's API Resource shape)
- **Computed getters** hinted at (`isOverdue`, `isPaid`)
- **Domain methods** hinted at (`canEditBy(user)`)
- **Nested models** (Bill contains BillMember[])

## Step 2: Inspect

```bash
ls src/modules/{Module}/ 2>/dev/null || echo "MODULE_MISSING"
ls src/modules/{Module}/models/ 2>/dev/null
ls src/modules/{Module}/types/ 2>/dev/null
```

## Step 3: Resolve Ambiguity

- Field shape unknown → check backend API Resource (`Modules/{Module}/app/Http/Resources/{Name}Resource.php`)
- Nested models → confirm: "Generate `BillMember` model too if missing?"
- Top-level (User) vs module-local → User in `src/models/`; module-owned in module

## Step 4: Build Context Blob

```
Context for vue-model agent:
- Module: {Module}
- Model: {Name}
- Path: src/modules/{Module}/models/{Name}.ts
- Interface: I{Name}
- Fields: [id, name, amount, status, members?, created_at, updated_at]
- Computed getters: [isPaid, isOverdue, totalApprovedSplit]
- Domain methods: [canEditBy(userId)]
- Static utilities: [calculateTotalAssigned(members)]
- Nested model conversions: members → BillMember instances
- Barrel update: src/modules/{Module}/models/index.ts
- Existing siblings: [BillMember.ts]
```

## Step 5: Delegate

Task tool, `subagent_type: "bench:vue-model"`, pass the blob.

## Step 6: Synthesize

> "Created `src/modules/Bill/models/Bill.ts`. Class implements `IBill`. Static `fromApi(this: void, data)` factory. Getters: `isPaid`, `isOverdue`. Domain methods: `canEditBy(userId)`. Nested `members` converted to `BillMember` instances."

## When to Ask vs Assume

- `static fromApi(this: void, ...)` → always (enables `.map(Bill.fromApi)`)
- Class + `I{Name}` interface → always
- Nested model conversion in constructor → assume yes when fields contain other models
- Section comments → always
