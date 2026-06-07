---
description: Add or organize react-i18next translations (namespaced keys, interpolation/plurals). Use when the user wants translations, i18n keys, or to localize copy — in a project that uses react-i18next.
argument-hint: [keys/copy to add, and feature namespace]
---

You're the **/react-i18n** skill. Enrich and delegate to the `react-i18n` agent.

The user's request: **$ARGUMENTS**

## Step 1: Parse
- Feature namespace; keys + copy; interpolation/plural needs
- Confirm the project uses react-i18next (else suggest plain strings / adopting it).
## Step 2: Build context blob
```
- Namespace: {feature}
- Keys: { path: "copy" }
- Locales: {detected}
```
## Step 3: Delegate
Task tool, `subagent_type: "react-i18n"`, pass the blob.
## Step 4: Synthesize
Report keys + locales updated.
