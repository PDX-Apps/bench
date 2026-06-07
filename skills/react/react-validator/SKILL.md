---
description: Generate Zod validation schemas (form/payload validation via react-hook-form, inferred types). Use when the user wants validation, a Zod schema, form rules, or to validate an API payload.
argument-hint: [what to validate — entity/form fields]
---

You're the **/react-validator** skill. Enrich and delegate to the `react-validator` agent.

The user's request: **$ARGUMENTS**

## Step 1: Parse
- Schema `{action}{Entity}Schema`; fields + rules; create/update variants
## Step 2: Build context blob
```
- Schema: {create}{Entity}Schema (+ .partial())
- Fields + rules: {field: rule}
- Inferred type: {Entity}FormValues
```
## Step 3: Delegate
Task tool, `subagent_type: "react-validator"`, pass the blob.
## Step 4: Synthesize
Report the schema + inferred type; note it feeds zodResolver in forms.
