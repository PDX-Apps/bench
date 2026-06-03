---
name: bench-add-domain
description: |
  Use this skill when the user has added a new domain or feature area to the
  project and wants Bench to capture its conventions. Triggers on
  "/bench-add-domain", "onboard the new {X} module", "scan the new auth
  domain", "we just added a billing module — bring Bench up to speed". Lighter
  weight than /bench-onboard — focuses on one domain rather than the whole project.
---

# /bench-add-domain

Adds Bench knowledge for a single new domain / module / feature area. Scans
just that area, decides whether pattern overrides or custom skills are
warranted, and proposes them.

## Usage

```
/bench-add-domain {name}                          # standard
/bench-add-domain {name} --path={path}            # explicit path if not inferrable
/bench-add-domain {name} --depth=deep
```

Examples:
- `/bench-add-domain Billing`
- `/bench-add-domain auth --path=apps/cloud/Modules/Auth`
- `/bench-add-domain reports --depth=deep`

## What this skill does

1. **Resolve the domain location**. Try in order:
   - `--path` if provided
   - `Modules/{name}/` (Laravel module convention)
   - `apps/{name}/`, `packages/{name}/`, `src/modules/{name}/`
   - Ask the user if ambiguous.

2. **Scan only that subtree** (per METHODOLOGY, scoped):
   - List artifacts present: controllers, models, components, stores, tests.
   - Sample a few of each.
   - Compare against project conventions (read CLAUDE.md + existing `.bench/patterns/`).

3. **Decide what's warranted**:
   - Does this domain follow the project's existing conventions? → just update
     CLAUDE.md to mention it.
   - Does it diverge from project conventions? → propose pattern overrides
     scoped to this domain (or surface the divergence as a question).
   - Does it have a unique workflow worth a custom skill? → propose
     `/bench-add-skill {workflow}`.

4. **Propose changes**:
   - CLAUDE.md update (mention the new domain under "Where new things go" or
     "Domain glossary").
   - Optional pattern overrides.
   - Optional custom skills.

5. **Apply approved changes**, run rebuild, summarize.

## What this skill does NOT do

- Modify code in the domain itself. Read-only scan.
- Rescan the entire project. Scope is the named domain.
- Skip user review. Every proposed write awaits approval.

## Why this exists separately from /bench-onboard

- `/bench-onboard` is for first-time setup of the whole project.
- `/bench-add-domain` is for ongoing: a new module/feature has landed, and
  Bench needs to learn its conventions without re-scanning everything.

Use `/bench-onboard` once. Use `/bench-add-domain` whenever a notable new
domain ships.

## Delegation

```
# Step 1: scoped claudemd-researcher pass to update domain section
Task(
  subagent_type: "claudemd-researcher",
  description: "Update CLAUDE.md to include {name} domain",
  prompt: """
  Scoped scan of the {name} domain at {resolved_path}.
  Update CLAUDE.md (diff mode) to mention the new domain where appropriate
  (Where new things go, Domain glossary, etc.).

  - depth: {depth}
  - project_root: {cwd}
  - force: false
  """
)

# Step 2 (if divergences found): pattern-researcher per candidate
# Step 3 (if unique workflow): skill-researcher per candidate
```

## Final report

```
Domain "{name}" added to Bench knowledge.

Updated:
- CLAUDE.md (mentioned {name} in {sections})
{- optional pattern overrides}
{- optional skill + worker pairs}

The next /api or /vue-component call in this domain will pick up its conventions.
```
