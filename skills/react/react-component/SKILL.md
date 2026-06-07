---
description: Generate React TSX components (cards, dialogs, forms, inputs, sections) for a React frontend. Use whenever the user mentions a React component, .tsx file, card, dialog, form, input, modal, or any UI piece in the React project.
argument-hint: [what the user needs]
---

You're the **/react-component** skill. Translate the user's UI request into an actionable delegation to the `react-component` agent.

The user's request: **$ARGUMENTS**

## Step 1: Parse

Extract:
- **Module / feature folder**
- **Component name** (PascalCase)
- **Folder**: Cards / Dialogs / Forms / Inputs / Sections / (root)
- The component name often signals the folder (`*Card.tsx` → Cards/, `*Dialog.tsx` → Dialogs/, `*Form.tsx` → Forms/)

## Step 2: Inspect

```bash
ls src/modules/{Module}/ 2>/dev/null || ls src/features/{Module}/ 2>/dev/null || echo "MODULE_MISSING"
ls src/modules/{Module}/components/{Folder}/ 2>/dev/null
ls src/modules/{Module}/i18n/ 2>/dev/null
ls src/components/ 2>/dev/null    # project-wide primitives
ls src/shared/ 2>/dev/null
```

## Step 3: Resolve Ambiguity

- Module missing → flag that the module needs to exist first
- Folder unclear → ask one question
- Form requested but no validators → flag for `/react-validator` or inline schemas
- Depends on missing service/model → flag and suggest `/react-service` or `/react-model`

## Step 4: Build Context Blob

```
Context for react-component agent:
- Module: {Module}
- Component name: {Name}.tsx
- Folder: components/{Folder}/
- Full path: src/modules/{Module}/components/{Folder}/{Name}.tsx
- Existing siblings: [BillCard.tsx, BillFormDialog.tsx]
- i18n namespace: {module}
- New i18n keys needed: [list, if known]
- Validators needed: [emailSchema, etc., if Form]
- Service/model dependencies: [BillService, Bill model]
- Reusable project primitives: (discover from src/components/, src/shared/)
- UI library in use: (discover from existing components — Radix? MUI? Chakra?)
```

## Step 5: Delegate

Task tool, `subagent_type: "react-component"`, pass the blob.

## Step 6: Synthesize

> "Created `src/modules/Household/components/Dialogs/InviteMemberDialog.tsx`. Wraps `InviteMemberForm`, uses `useMutation` for `HouseholdService.inviteMember()`. New i18n keys under `household.invite.*`."

## When to Ask vs Assume

- **Named export, NOT default** → always (pages are the exception)
- **Folder clear from name** → don't ask
- **UI library** → discover from sibling components; don't assume
- **Tests** → suggest `/react-test` after; don't generate here
