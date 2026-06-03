---
name: bench-audit
description: |
  Use this skill when the user wants to check whether Bench's project knowledge
  is still accurate — i.e., CLAUDE.md, pattern overrides, and custom skills
  haven't drifted from the actual codebase. Triggers on "/bench-audit", "audit
  Bench config", "is CLAUDE.md still accurate?", "check if our patterns drifted",
  "rescan the project and tell me what changed".
---

# /bench-audit

Audits the project's Bench configuration (CLAUDE.md + `.bench/`) against the
current state of the codebase. Reports drift and proposes updates. Read-only
by default — only writes on user approval.

## Usage

```
/bench-audit                          # standard depth
/bench-audit --depth=shallow          # quick check
/bench-audit --depth=deep             # thorough
/bench-audit --apply                  # auto-apply recommended fixes (use carefully)
```

## What this skill does

1. **Read existing Bench config**:
   - `{project_root}/CLAUDE.md`
   - `{project_root}/.bench/patterns/**`
   - `{project_root}/.bench/skills/**`
   - `{project_root}/.bench/agents/**`

2. **Rescan the project** (per METHODOLOGY) at the chosen depth.

3. **Compare** existing config against fresh observations:

   For each claim in CLAUDE.md:
   - Is the path still valid? (Layout changed?)
   - Is the convention still observed? (Did the team drift?)
   - Is the stack version still current? (composer.json / package.json bumped?)

   For each pattern override:
   - Does the artifact still exist in the codebase?
   - Is the pattern's convention still followed by recent files?
   - Has Bench core's base pattern changed in a way that affects the override?

   For each custom skill + worker:
   - Does the target artifact type still exist?
   - Are the patterns the worker reads still in place?

4. **Produce a drift report**:

   ```
   ## CLAUDE.md
   - ✅ Stack section accurate
   - ⚠️ "Tests use Pest" — observed 60% Pest / 40% PHPUnit. Drifting?
   - ❌ References `apps/cloud/Modules/Auth/` — directory no longer exists (renamed to Identity?)

   ## .bench/patterns/laravel/controller.md
   - ✅ Convention still followed in 18/20 recent controllers
   - ⚠️ 2 recent controllers use a new pattern not captured here

   ## .bench/skills/saga/
   - ✅ Skill + worker intact
   - ⚠️ No new sagas have been created since this skill landed — usage data: 0
   ```

5. **Propose targeted fixes**:
   - "Update CLAUDE.md to fix the Auth → Identity rename" → diff
   - "Update controller pattern to reflect the new sub-convention" → diff
   - "Consider removing /saga skill — unused" → suggestion

6. **Apply** (only if `--apply` flag passed AND user confirms each change), or
   leave the report on screen for the user to act on manually.

## What this skill does NOT do

- Auto-fix without confirmation (unless `--apply` is explicitly passed).
- Delete pattern overrides or skills automatically.
- Modify code in the project — only `.bench/` and `CLAUDE.md`.

## When to run this

- Quarterly, as a hygiene check.
- After a major refactor.
- When a Bench-generated artifact "feels off" — a sign config has drifted.
- Before publishing or sharing the project, to make sure CLAUDE.md is sharp.

## Delegation

```
# Delegate the rescan to claudemd-researcher in audit mode
Task(
  subagent_type: "claudemd-researcher",
  description: "Audit CLAUDE.md against current codebase",
  prompt: """
  AUDIT MODE: do NOT write anything. Compare current CLAUDE.md against a
  fresh scan and report drift only.

  - depth: {depth}
  - project_root: {cwd}
  """
)

# For each pattern override that looks suspect, run pattern-researcher in
# audit mode for that domain
```

## Final report

```
Bench audit complete.

Healthy:
- {file} — no drift detected
- {file} — no drift detected

Drifted (review recommended):
- CLAUDE.md: {short description}
- .bench/patterns/{group}/{name}.md: {short description}

Unused (consider removing):
- .bench/skills/{name}/ — no usage signal

Run /bench-update-claudemd / /bench-add-pattern to apply fixes, or rerun
with --apply to walk through each change interactively.
```
