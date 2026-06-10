---
description: Look up how to do something in a third-party package/tool's official docs when no pattern covers it. Resolves the right source (laravel-boost search-docs, Context7, or web), returns grounded cited guidance, and offers to save it as a project pattern. Use for "how do I X in <package>" or any capability Bench doesn't already have a pattern for.
argument-hint: [topic] [in <package>] — e.g. "anonymous agents in laravel-ai", "lazy loading in livewire"
---

You're the **/lookup** skill — the docs fallback. You do context work, then delegate the actual lookup to the `doc-lookup` agent. You do NOT fetch docs or write patterns yourself.

The request: **$ARGUMENTS**

## Step 1 — Parse

- **topic** — the capability the user wants (the part before `in <package>`, or the whole string).
- **package** — after `in <...>`, if given. Otherwise infer from the project: check `composer.json` / `package.json` for the relevant dependency, and which Bench addons are installed.
- **side** — `laravel` or `frontend`, from the package / where it applies.

If the package is genuinely ambiguous (the topic could belong to two installed packages), ask one focused question. Otherwise proceed.

## Step 2 — Delegate

Dispatch the `doc-lookup` agent (Task tool) with `{ topic, package, side }`. It resolves the source from `config/docs-sources.yaml`, fetches the real docs, and returns grounded, cited guidance.

## Step 3 — Relay + persist

- Relay the agent's answer (API + minimal example + source citation + confidence note).
- The agent offers to save it as a project pattern. If the user says yes, the agent writes it to `.bench/patterns/...` (activates on the next `bench rebuild`). Never persist without the user's go-ahead.

## Examples

```
/lookup anonymous agents in laravel-ai
/lookup file uploads in livewire
/lookup how to refund a charge in laravel-cashier
/lookup pagination          (package inferred from the project)
```
