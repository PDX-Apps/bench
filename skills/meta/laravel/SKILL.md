---
description: Backend (Laravel) router. Turns a backend request into the right artifact(s) — a single class, a multi-file feature (an endpoint = controller + request + resource + route), a spec/feature via the implement workflow. Invoked by /bench, or directly.
argument-hint: [backend feature / artifact / spec]
---

You're the **/laravel** skill — the backend router. Decompose the request into backend artifacts and delegate each to its agent via the Task tool. You do NOT read pattern files or write code — the agents do.

The request: **$ARGUMENTS**

## Step 1: Classify

- **single artifact** → one agent (see the table).
- **bounded feature** → the few artifacts it needs, in dependency order. Common shapes:
  - **CRUD endpoint** → controller (resource) + request + resource + route (+ policy if access-controlled)
  - **single action endpoint** ("mark order paid") → invokable controller + request + route (+ policy)
  - **related non-CRUD actions** (accept/deny/cancel) → grouped controller + requests + routes (+ policy)
- **spec / PRD / ticket, or a broad feature** → the **`implement`** workflow agent (it reads the source and builds the whole thing in isolation).

## Step 2: Resolve ambiguity

- Operation type unclear (CRUD vs invokable vs grouped) → ask one question.
- An endpoint needs a model that doesn't exist → include the `model` agent first, or flag it.
- Otherwise pick a sane default and proceed.

## Step 3: Delegate (Task tool, one agent per artifact)

| Artifact | `subagent_type` |
|----------|-----------------|
| Model / query builder / domain methods | `model` |
| Migration | `migration` |
| Factory | `factory` |
| Seeder | `seeder` |
| Resource/invokable/grouped controller | `controller` |
| FormRequest | `request` |
| API Resource | `resource` |
| Route(s) | `route` |
| Action | `action` |
| Domain service | `service` |
| Policy | `policy` |
| Event | `event` |
| Listener | `listener` |
| Job | `job` |
| Console command | `console` |
| Middleware | `middleware` |
| Cast | `cast` |
| Enum | `enum` |
| Validation rule | `rule` |
| Exception | `exception` |
| Trait | `trait` |
| Service provider | `provider` |
| Feature test / unit test | `feature-test` / `unit-test` |
| PHPDoc | `phpdoc` |
| Spec / broad feature | `implement` |

For a multi-artifact feature, spawn agents in dependency order (model → migration → action → request → controller → resource → route → policy → tests) and wait for each. Give each agent a focused brief: the artifact name, the model/fields/operation it concerns, and any non-default location from the project's `CLAUDE.md`.

## Step 4: Report

Summarize at the feature level: artifacts created (paths), what behavior/endpoints now exist, test status, and any follow-ups (e.g. suggest tests). Don't dump the agents' raw output.
