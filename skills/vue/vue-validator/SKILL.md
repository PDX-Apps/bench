---
description: Generate Zod validation schemas (form/payload validation, inferred types). Use when the user wants validation, a Zod schema, form rules, or to validate an API payload.
argument-hint: [what to validate — entity/form fields]
---

You're the **/vue-validator** skill. Enrich and delegate to the `vue-validator` agent.

The user's request: **$ARGUMENTS**

## Step 1: Parse
- Schema `{action}{Entity}Schema`; the fields + rules; whether create/update variants are needed

## Step 2: Build context blob
```
- Schema: {create}{Entity}Schema  (+ .partial() for update if needed)
- Fields + rules: {field: rule, ...}
- Inferred type export: {Entity}FormValues
```

## Step 3: Delegate
Task tool, `subagent_type: "vue-validator"`, pass the blob.

## Step 4: Synthesize
Report the schema(s) + inferred type; note it's the source of truth for the form + payload type.
