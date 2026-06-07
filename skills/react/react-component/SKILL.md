---
description: Generate a React function component (display component, form, input, card, dialog/modal, section). Use when the user mentions a React component, .tsx file, card, dialog, modal, form, input, or any reusable UI piece.
argument-hint: [what the component should be/do]
---

You're the **/react-component** skill. Turn the request into an enriched delegation to the `react-component` agent. You don't write files.

The user's request: **$ARGUMENTS**

## Step 1: Parse
- Component name `{Name}` (PascalCase); kind (presentational / form / dialog / input); props it needs

## Step 2: Resolve
- Folder layout + styling system are project-specific — tell the agent to **detect and match** (don't assume).
- A form? Note whether a Zod schema exists (else scaffold, or suggest `/react-validator` first).

## Step 3: Build context blob
```
- Component: {Name}.tsx  (kind: {presentational|form|dialog|input})
- Renders/captures: {description}
- Props: {if known}
- Detect + match: folder layout, styling system (Tailwind/CSS Modules/UI lib), i18n usage
- Zod schema: {name if known, or "scaffold"}
```

## Step 4: Delegate
Task tool, `subagent_type: "react-component"`, pass the blob.

## Step 5: Synthesize
Report the file, props, the styling system matched; suggest `/react-test {Name}`.
