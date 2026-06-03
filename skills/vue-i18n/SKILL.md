---
description: Generate or update vue-i18n translation files for a Vue 3 frontend. Use whenever the user mentions translations, i18n, localization, language strings, or translation keys in the frontend project.
argument-hint: [what the user needs]
---

You're the **/vue-i18n** skill. Translate the user's i18n request into an enriched delegation to the `vue-i18n` agent.

The user's request: **$ARGUMENTS**

## Step 1: Parse

Extract:
- **Module** (Bill, Household, Auth, etc.)
- **Namespace** within module (typically module name lowercase)
- **Section**: pages | card | form | dialog | actions | breadcrumb | notifications | status
- **Keys to add**: structured tree
- **Locales**: discover from project (write to ALL configured)

## Step 2: Inspect

```bash
ls src/modules/{Module}/i18n/ 2>/dev/null || echo "MODULE_MISSING_OR_NO_I18N"
ls src/locales/ 2>/dev/null
ls src/i18n/ 2>/dev/null
cat src/modules/{Module}/i18n/{first-locale}/{namespace}.ts 2>/dev/null
```

## Step 3: Resolve Ambiguity

- Non-English translations not provided → placeholders + flag for review
- Section unclear → infer from key names
- New namespace vs existing → if new, also update `{locale}/index.ts` to aggregate

## Step 4: Build Context Blob

```
Context for vue-i18n agent:
- Module: {Module}
- Namespace: {namespace}
- Locales detected: [en-US, es-MX]  (write to all)
- Files to update: src/modules/{Module}/i18n/{locale}/{namespace}.ts (per locale)
- Aggregator update needed: yes/no
- Section: pages.list | actions | notifications.errors | etc.
- Keys to add per locale:
    en-US: pages.list.title: "My Bills"
    es-MX: pages.list.title: "Mis Cuentas"
- Existing keys (don't overwrite): [...]
```

## Step 5: Delegate

Task tool, `subagent_type: "bench:vue-i18n"`, pass the blob.

## Step 6: Synthesize

> "Added 6 i18n keys under `bill.pages.list.*` across 2 locales. No aggregator update needed."

## When to Ask vs Assume

- All configured locales → always; discover from project
- Non-English translations → placeholders + flag for review
- Hierarchical structure → always
