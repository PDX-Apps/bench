# Planning artifacts — shared conventions

bench-plan produces one of several artifact types from the same deep codebase gather. These conventions are shared across all of them (implementation plan, spec/design doc, PRD, ADR, ticket). The per-type patterns (`PLAN-001…005`) describe each artifact's structure; this file describes what's common.

## Where artifacts live

Read `{project_root}/.bench/planning.yaml` (schema: `<PLUGIN_ROOT>/config/planning.example.yaml`) for the project's choices. Defaults if absent:

- **Feature artifacts** (plan, spec, PRD) live in-repo under **`{artifact_dir}/NNN-feature-slug/`** — `artifact_dir` defaults to `specs/`. One folder per feature, so a feature's `plan.md` / `spec.md` / `prd.md` are siblings (the Spec Kit / Kiro convention). Compute `NNN` as the next zero-padded number after the highest existing folder (`001`, `002`, …); slug = kebab-case feature name.
- **ADRs** live separately in the **decision log** — `docs/adr/NNNN-title.md` by convention. **Detect** an existing location first (`docs/adr/`, `docs/decisions/`, `doc/adr/`); use it if found, else default `docs/adr/` and confirm. ADRs are numbered independently of feature folders.
- **Tickets** are emitted **to the conversation, paste-ready** by default (the team pastes into Jira/Linear/GitHub); only write a file if the user asks.

When `feature_folders: false`, write flat files into `{artifact_dir}/` named `NNN-feature-slug.{plan|spec|prd}.md` instead of a folder.

## Acceptance criteria — notation

Criteria must be **testable and unambiguous**. The notation comes from `planning.yaml` `criteria:` (default **`gherkin`**):

- **`gherkin`** (default) — `Given <context>, When <action>, Then <outcome>`. Familiar, maps directly to tests.
  ```gherkin
  Scenario: Member redeems a valid coupon
    Given an active cart and an unused coupon "SAVE10"
    When the member applies the coupon at checkout
    Then the order total is reduced by 10% and the coupon is marked used
  ```
- **`ears`** — Easy Approach to Requirements Syntax; rigorous, individually testable:
  - Ubiquitous: *The system SHALL …*
  - Event: *WHEN `<trigger>`, the system SHALL …*
  - State: *WHILE `<state>`, the system SHALL …*
  - Unwanted: *IF `<condition>`, THEN the system SHALL …*
  - Optional: *WHERE `<feature>`, the system SHALL …*
- **`prose`** — plain bulleted observable outcomes, when the team doesn't want a formal notation.

Whatever the notation, each criterion is **observable** (an endpoint returns X, a row is written, a screen shows Y) — never "code is written".

## Tasks — ordering & parallelism

When an artifact contains a task list (implementation plan; optionally spec), use the **dependency-ordered + parallel-marker** convention (Spec Kit's, which maps onto bench's `implement` workflow):

- Order tasks by dependency: data/schema → backend (model/action/controller/route) → API (resource) → frontend (types/validators → query → components → page → route) → tests.
- Mark a task **`[P]`** when it has **no dependency on another uncommitted task** and can run in parallel with its siblings. The implement workflow can fan these out.
- Each task names the **artifact(s)** it produces and the **Bench skill/agent** that handles it (`/migration`, `/controller`, `/vue-component`), so `implement` maps task → agent.

```
1. [ ] Add coupons table + model            → /migration, /model      (data)
2. [ ] [P] CouponData DTO                    → /action or /cast
3. [ ] [P] RedeemCoupon action               → /action               (depends: 1)
4. [ ] Checkout controller wires redemption  → /controller           (depends: 3)
5. [ ] [P] Feature test: redeem valid coupon → /feature-test         (depends: 4)
```

## Grounding (all artifacts)

- Every claim — paths, signatures, surfaces, constraints — traces to a file the gather actually read. Cite real paths.
- Surface **open questions** the source didn't answer rather than guessing.
- Keep artifacts **portable** — describe *what* each step/decision is, not a brittle command script.
