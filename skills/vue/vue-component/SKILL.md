---
description: Generate a Vue 3 single-file component (display component, form, input, card, dialog/modal, section). Use when the user mentions a Vue component, .vue file, card, dialog, modal, form, input, or any reusable UI piece.
argument-hint: [what the component should be/do]
---

You're the **/vue-component** skill. Turn the request into an enriched delegation to the `vue-component` agent. You don't write files.

The user's request: **$ARGUMENTS**

## Step 1: Parse
- Component name `{Name}` (PascalCase, multi-word)
- Kind: presentational / form / dialog / input wrapper
- What it displays or captures; props/emits it needs

## Step 2: Resolve
- Where components live + the styling system are project-specific — tell the agent to **detect and match** (don't assume a folder or CSS approach).
- A form? Note whether a Zod schema exists (else the agent scaffolds one or you suggest `/vue-validator` first).
- Only ask if genuinely ambiguous (e.g. display vs form unclear).

## Step 3: Build context blob
```
- Component: {Name}.vue  (kind: {presentational|form|dialog|input})
- Renders/captures: {description}
- Props/emits: {if known}
- Detect + match: folder layout, styling system (Tailwind/scoped/UI lib), i18n usage
- Zod schema: {name if known, or "scaffold"}
```

## Step 4: Delegate
Task tool, `subagent_type: "vue-component"`, pass the blob.

## Step 5: Synthesize
Report the file created, props/emits, the styling system matched, and suggest `/vue-test {Name}`.
