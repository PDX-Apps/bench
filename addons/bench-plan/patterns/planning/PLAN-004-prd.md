# PRD (Product Requirements Document) — format

The **what & why** of a feature, from the user/business view — *no implementation*. It defines the problem, who it's for, what success looks like, and the testable acceptance criteria. Use it to capture intent before any technical design. The *how* comes later in a spec; the ordered build in a plan.

A bench-plan PRD is still **grounded** — the gather checks the codebase so the PRD reflects what exists today (current behavior, real entities, what's already built) rather than inventing context. Lives at `{artifact_dir}/NNN-feature-slug/prd.md`.

```markdown
# PRD: {Feature name}

## Problem
{The user/business problem, and why it matters now. Ground it: what does the
product do today (real, from the code) that makes this a gap?}

## Goals & non-goals
- **Goals:** {the outcomes this feature must achieve}
- **Non-goals:** {explicitly out of scope — prevents scope creep}

## Users
{Who this is for — personas/roles. Reference the real roles/models if the codebase
has them (e.g. existing `Role` values).}

## User stories
- As a {role}, I want {capability} so that {benefit}.
- ...

## Functional requirements
{What the feature must do, as numbered requirements — each one observable.}

## Acceptance criteria
{Testable criteria in the project's notation (default Gherkin). These
become the test contract and can seed the ticket.}

## Success metrics
{How we'll know it worked — the signal/measure. Omit if genuinely not measurable.}

## Out of scope
{What this explicitly does not cover.}
```

## Conventions

- **No implementation.** A PRD says *what* and *why*, never *how* — if you're naming classes or designing schema, write a spec.
- **Acceptance criteria are the bridge** — testable, so they flow straight into a ticket or a plan's test strategy.
- **Grounded, not speculative** — anchor the problem and users in what the codebase actually is today; mark anything you couldn't confirm as an open question.
- **One feature per PRD.** Epics get decomposed into per-feature PRDs.
