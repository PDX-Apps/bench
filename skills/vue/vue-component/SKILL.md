---
description: Generate Vue 3 SFCs (cards, dialogs, forms, inputs, sections) for a Vue 3 frontend. Use whenever the user mentions a Vue component, .vue file, card, dialog, form, input, modal, or any UI piece in the frontend project.
argument-hint: [what the user needs]
---

You're the **/vue-component** skill. Translate the user's UI request into an actionable delegation to the `vue-component` agent. Skip obvious-case steps but always do Steps 4–6.

The user's request: **$ARGUMENTS**

## Step 1: Parse the Request

Extract:
- **Module / feature folder** (Bill, Household, Auth, Core, etc.) — if implicit, infer from referenced resource
- **Component name** (e.g., `BillCard`, `InviteMemberDialog`, `MemberSplitInput`)
- **Folder** the component belongs in:
  - `Cards/` — display a single resource summary
  - `Dialogs/` — modal wrapper (often contains a Form)
  - `Forms/` — form component (consumed by a Dialog or Page)
  - `Inputs/` — reusable input wrapper
  - `Sections/` — page section
  - (root) — utility/cross-cutting

The component name often signals the folder (`*Card.vue` → Cards/, `*Dialog.vue` → Dialogs/, `*Form.vue` → Forms/).

## Step 2: Inspect the Project

```bash
ls src/modules/{Module}/ 2>/dev/null || ls src/features/{Module}/ 2>/dev/null || echo "MODULE_MISSING"
ls src/modules/{Module}/components/{Folder}/ 2>/dev/null
ls src/modules/{Module}/i18n/ 2>/dev/null
ls src/components/ 2>/dev/null    # project-wide shared primitives
ls src/shared/ 2>/dev/null
```

## Step 3: Resolve Ambiguity

- Module missing → confirm: "No `{Module}` module found. Use `/vue-new-module` first?"
- Folder unclear → ask one question
- Form requested but no validators exist → flag: "Delegate to `/vue-validator` first, or include schemas inline?"
- Depends on missing service/model → flag and suggest `/vue-service` or `/vue-model`

For obvious cases, proceed without asking.

## Step 4: Build Context Blob

```
Context for vue-component agent:
- Module: {Module}
- Component name: {Name}.vue
- Folder: components/{Folder}/
- Full path: src/modules/{Module}/components/{Folder}/{Name}.vue
- Existing siblings: [BillCard.vue, BillFormDialog.vue, ...]
- i18n namespace: {module} (discover existing keys from module's i18n)
- New i18n keys needed: [list, if known]
- Validators needed: [emailSchema, etc., if it's a Form]
- Service/model dependencies: [BillService, Bill model — confirmed exist]
- Reusable project primitives: (discover from src/components/ and src/shared/)
```

## Step 5: Delegate

Task tool, `subagent_type: "bench:vue-component"`, pass the blob.

## Step 6: Synthesize

> "Created `src/modules/Household/components/Dialogs/InviteMemberDialog.vue`. Wraps `InviteMemberForm`, calls `HouseholdService.inviteMember()`. New i18n keys added under `household.invite.*`. Uses Zod (`emailSchema`, `nameSchema`). Suggest `/vue-test InviteMemberDialog`."

## When to Ask vs Assume

- **Folder clear from name** → don't ask
- **Folder ambiguous** → ask one question
- **i18n keys** → assume new keys are needed; discover project's locales from existing files
- **Tests** → suggest `/vue-test` after; don't generate here

## Anti-Patterns

- Passing raw `$ARGUMENTS` to the agent
- Reading entire sibling components (just need the file list)
- Hardcoding locales — agent should discover from the project
- Generating the component WITHOUT checking project-wide shared primitives
