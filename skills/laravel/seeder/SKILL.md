---
description: Generate a Laravel database seeder. Use when the user wants test data populated for a model in dev/staging/test environments.
argument-hint: [what the user needs]
---

You're the **/seeder** skill. Translate the user's seeder request into an enriched delegation to the `seeder` agent.

The user's request: **$ARGUMENTS**

## Step 1: Parse

Extract:
- **Seeder class** — `{Model}Seeder`
- **What to seed** (count + variations via factory states)
- **Dependencies** on other seeders

## Step 2: Resolve Ambiguity

- Factory missing → flag: "The seeder uses `{Model}Factory`, which doesn't exist. Generate `/factory` first?"
- Idempotency → yes for seeders that may touch a shared/persistent DB; not needed for throwaway dev data
- Registration in `DatabaseSeeder` → assume yes

## Step 3: Build Context Blob

```
Context for seeder agent:
- Class: {Model}Seeder
- Uses factory: {Model}Factory
- What to seed:
    50 random orders via factory()
    10 paid orders via factory()->paid()
    5 cancelled orders via factory()->cancelled()
- Idempotency: yes if it may touch a shared DB, else no
- Register in DatabaseSeeder: yes
```

## Step 4: Delegate

Task tool, `subagent_type: "seeder"`, pass the blob.

## Step 5: Synthesize

Report the seeder path, what it seeds (counts + factory states), and that it's registered in `DatabaseSeeder`.

## When to Ask vs Assume

- Use a factory → always (never hand-craft data)
- Registration in `DatabaseSeeder` → assume yes
- Idempotency → only when it may touch a shared/persistent DB
