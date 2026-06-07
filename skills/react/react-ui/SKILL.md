---
description: Generate a complete React UI feature — page + components + forms + dialogs + validators + i18n keys, all wired together. Use whenever the user asks for a UI feature, screen, dialog, form flow, or any multi-artifact frontend work where they describe the user-facing behavior rather than a single file. Symmetric to /laravel on the backend.
argument-hint: [what the user needs]
---

You're the **/react-ui** skill — the React frontend feature coordinator. Translate the user's UI feature request into an enriched delegation to the `react-ui` agent.

The user's request: **$ARGUMENTS**

## Step 1: Parse

Extract:
- **Module** (Bill, Household, Auth, etc.)
- **Feature description** — what user-facing behavior the user wants ("invite a member", "list and create bills")
- **Artifacts likely needed**: page (new or existing?), card/list component, dialog, form, validators (Zod), i18n keys, hooks
- **Dependencies**: which service the feature consumes (must already exist or be flagged)

## Step 2: Inspect

```bash
ls src/modules/{Module}/ 2>/dev/null || echo "MODULE_MISSING"
ls src/modules/{Module}/pages/ 2>/dev/null
ls src/modules/{Module}/components/ 2>/dev/null
ls src/modules/{Module}/services/ 2>/dev/null
ls src/modules/{Module}/models/ 2>/dev/null
ls src/modules/{Module}/validators/ 2>/dev/null
ls src/modules/{Module}/hooks/ 2>/dev/null
ls src/modules/{Module}/i18n/ 2>/dev/null
# Project-wide shared primitives
ls src/components/ 2>/dev/null
ls src/shared/ 2>/dev/null
```

## Step 3: Resolve Ambiguity

- Module missing → flag that the `{Module}` module needs to exist first
- Service missing → flag: "Feature needs `BillService.invite()` — service doesn't exist. Generate `/react-service` first or proceed assuming you'll add it?"
- Model missing → same, flag for `/react-model`
- Page exists vs new → confirm: "Update existing `BillsPage` or create new `BillCreatePage`?"
- For obvious cases, proceed without asking

## Step 4: Build Context Blob

```
Context for react-ui agent:
- Module: {Module}
- Feature: brief user-facing description
- Artifacts to generate (in dependency order):
    1. validators/invitationValidators.ts    (new Zod schemas: emailSchema, roleSchema)
    2. i18n/{locale}/household.ts            (new keys: household.invite.*, all locales)
    3. hooks/useInviteMember.ts              (TanStack Query mutation wrapping the service)
    4. components/Forms/InviteMemberForm.tsx
    5. components/Dialogs/InviteMemberDialog.tsx
    6. (update) pages/HouseholdMembersPage.tsx   (add button + dialog mount)
- Existing dependencies (confirmed exist):
    HouseholdService.inviteMember() at src/modules/Household/services/HouseholdService.ts
    Household, HouseholdMember models
- Reusable primitives to consider: (discover from src/components/, src/shared/)
- Sibling components for naming/style: [HouseholdMemberCard.tsx, ...]
- i18n namespace: household; new keys under household.invite.{form,dialog,actions,notifications}.*
- Locales detected: [en-US, es-MX]  (discover from src/modules/{Module}/i18n/)
```

## Step 5: Delegate

Task tool, `subagent_type: "react-ui"`, pass the blob.

## Step 6: Synthesize

> "Built household member invitation flow: 7 files (1 validator, 1 i18n update per locale, 1 hook, 1 form, 1 dialog, updated 1 page). Wired to existing `HouseholdService.inviteMember()` via `useInviteMember` mutation. New i18n keys under `household.invite.*`. Validators: `inviteEmailSchema`, `inviteRoleSchema`. Suggest `/react-test InviteMemberDialog` for coverage."

Mention any flags from the agent (missing service method, suggested follow-ups).

## When to Ask vs Assume

- Page existence → check via inspect, don't ask
- i18n in all configured locales → always (discover from project)
- Reusable primitives → always check shared/ and components/ first to avoid reinventing
- Tests → don't generate; suggest `/react-test` after
- Service/model missing → flag with suggested skill, don't proceed silently
