---
concern: planning
title: Planning artifacts (location & notation)
order: 62
when: always
detect: ls -d specs docs/specs 2>/dev/null | head -1 || echo "specs"
questions:
  - id: artifact_dir
    ask: "Where should feature planning artifacts (plan / spec / PRD) live? One folder per feature is created under it. The ecosystem default is specs/."
    default: detect
  - id: criteria
    ask: "Default notation for acceptance criteria?"
    options: [gherkin, ears, prose]
    default: gherkin
  - id: feature_folders
    ask: "Group each feature's artifacts in their own folder (specs/NNN-feature/), or write flat files?"
    options: [folder, flat]
    default: folder
  - id: adr_location
    ask: "Where should ADRs (architecture decision records) live — the project-wide decision log (docs/adr/), or co-located inside each feature's folder alongside its plan/spec/PRD?"
    options: [decision-log, feature-folder]
    default: decision-log
output: config:.bench/planning.yaml
---

## Apply

Write `.bench/planning.yaml` — how this project lays out and writes planning artifacts, read by the `plan-researcher` agent. Match the schema at `<PLUGIN_ROOT>/config/planning.example.yaml`:

```yaml
# .bench/planning.yaml — read by the plan-researcher agent
artifact_dir: "{artifact_dir}"   # feature artifacts live under here (default: specs)
criteria: {criteria}             # acceptance-criteria notation: gherkin | ears | prose
feature_folders: {true|false}    # 'folder' → true (specs/NNN-feature/); 'flat' → false
adr_location: {decision-log|feature-folder}  # where ADRs go (default: decision-log)
```

Rules:

- `feature_folders`: map the answer `folder` → `true`, `flat` → `false`.
- `adr_location`: pass the answer through as-is (`decision-log` or `feature-folder`). `feature-folder` co-locates a feature's ADR(s) with its plan/spec/PRD; it presupposes `feature_folders: true` (with flat files there's no folder to co-locate into, so ADRs fall back to the decision log).
- Omit a key whose value equals the documented default — the agent's fallbacks cover it.
- This config governs **feature artifacts** (plan/spec/PRD) and **where ADRs land** (`adr_location`). **Tickets** still emit to the conversation paste-ready — that isn't set here. See `<PLUGIN_ROOT>/patterns-built/planning/PLAN-000-conventions.md`.
