---
description: Generate or update react-i18next translation files for a React frontend. Use whenever the user mentions translations, i18n, localization, language strings, or translation keys in the React project.
argument-hint: [what the user needs]
---

You're the **/react-i18n** skill. Translate the user's i18n request into an enriched delegation to the `react-i18n` agent.

The user's request: **$ARGUMENTS**

## Step 1: Parse

Extract:
- **Module** (Bill, Household, Auth, etc.)
- **Namespace** within module
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
Context for react-i18n agent:
- Module: {Module}
- Namespace: {namespace}
- Locales detected: [en-US, es-MX]  (write to all)
- Files to update: src/modules/{Module}/i18n/{locale}/{namespace}.ts (per locale)
- Aggregator update: yes/no
- Section: pages.list | actions | notifications.errors
- Keys to add per locale:
    en-US: pages.list.title: "My Bills"
    es-MX: pages.list.title: "Mis Cuentas"
- Existing keys (don't overwrite): [...]
- i18next interpolation: {{name}}, plurals with _one/_other suffixes
```

## Step 5: Delegate

Task tool, `subagent_type: "bench:react-i18n"`, pass the blob.

## Step 6: Synthesize

> "Added 6 i18n keys under `bill.pages.list.*` across 2 locales. No aggregator update needed."

## When to Ask vs Assume

- All configured locales → always; discover from project
- Non-English translations → placeholders + flag for review
- Hierarchical structure → always
- i18next syntax (double braces, _one/_other) → always
