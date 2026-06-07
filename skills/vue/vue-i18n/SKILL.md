---
description: Add or organize vue-i18n translations (locale messages, hierarchical keys, interpolation/plurals). Use when the user wants translations, i18n keys, or to localize copy — in a project that uses vue-i18n.
argument-hint: [keys/copy to add, and feature namespace]
---

You're the **/vue-i18n** skill. Enrich and delegate to the `vue-i18n` agent.

The user's request: **$ARGUMENTS**

## Step 1: Parse
- Feature namespace; the keys + copy; interpolation/plural needs
- Confirm the project uses vue-i18n (else suggest plain strings / adopting it).

## Step 2: Build context blob
```
- Namespace: {feature}
- Keys: { path: "copy", ... }
- Locales to update: {detected, e.g. en, es}
```

## Step 3: Delegate
Task tool, `subagent_type: "vue-i18n"`, pass the blob.

## Step 4: Synthesize
Report keys added + locales updated.
