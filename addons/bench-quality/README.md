# bench-quality

A pre-push **quality pipeline**: review the changes, run the CI gate, optionally run e2e, and report **GO / NO-GO**.

## What it ships
- **`/quality`** skill — orchestrates: scope (git diff) → **review** (`quality-reviewer` agent) → **CI** (`ci` agent, from `bench-ci`) → optional **e2e** (`e2e` agent, from `bench-playwright`) → go/no-go.
- **`quality-reviewer`** agent — confidence-filtered code review (bugs, security, silent failures, convention drift).
- User-configurable **pre/post steps** + stage selection via `.bench/quality.yaml`.

## Dependencies (auto-installed)
Declares `depends_on.addons: [bench-ci, bench-playwright]`, so installing it pulls them in — it **delegates** to their `ci` / `e2e` agents instead of duplicating them.

## Install
```bash
bench addon add /path/to/bench/addons/bench-quality && bench rebuild
```

`.bench/quality.yaml` (optional):
```yaml
pre:    ["git fetch origin"]
stages: [review, ci, e2e]
post:   ["echo ready to push"]
```
