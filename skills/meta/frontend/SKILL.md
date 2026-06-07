---
description: Frontend router (Vue or React). Detects the project's framework, then turns a frontend request into the right artifact(s) — a single piece (component, page, store, …), a full UI feature, or a spec via the implement workflow. Invoked by /bench, or directly.
argument-hint: [frontend feature / artifact / spec]
---

You're the **/frontend** skill — the frontend router. Detect the framework, decompose the request, and delegate each artifact to its agent via the Task tool. You do NOT read pattern files or write code — the agents do.

The request: **$ARGUMENTS**

## Step 1: Detect the framework

```bash
grep -qE '"vue"' package.json frontend/package.json 2>/dev/null && echo vue
grep -qE '"react"' package.json frontend/package.json 2>/dev/null && echo react
```

Use the detected framework's agent set (`vue-*` or `react-*`). If both or neither resolve (monorepo / unusual layout), ask. The project's `CLAUDE.md` may state where the frontend lives.

## Step 2: Classify

- **single artifact** → one agent (see table)
- **full UI feature** (page + components + form + dialog + validators + i18n) → the `{fw}-ui` agent
- **spec / PRD / ticket, or a broad feature** → the `{fw}-implement` workflow agent

## Step 3: Delegate (Task tool; `{fw}` = `vue` or `react`)

| Artifact | `subagent_type` |
|----------|-----------------|
| Component | `{fw}-component` |
| Page | `{fw}-page` |
| Layout | `{fw}-layout` |
| Store | `{fw}-store` |
| Service | `{fw}-service` |
| Model | `{fw}-model` |
| Route | `{fw}-route` |
| i18n | `{fw}-i18n` |
| Validator | `{fw}-validator` |
| Composable (Vue) / Hook (React) | `vue-composable` / `react-hook` |
| Test | `{fw}-test` |
| Full UI feature | `{fw}-ui` |
| Spec / broad feature | `{fw}-implement` |

For a multi-artifact feature, spawn agents in dependency order (model/types → service → store → components → page → route → i18n → tests) and wait for each. Brief each agent with the artifact, the feature context, and any non-default location from `CLAUDE.md`.

## Step 4: Report

Summarize at the feature level: artifacts created (paths), routes/screens now available, test status, follow-ups. Don't dump the agents' raw output.
