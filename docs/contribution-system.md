# Bench — Contribution System (override + aggregation)

**Status:** Phases 1–2 IMPLEMENTED (2026-06-06) for **patterns + skills + agents** — `replace` (default, backward-compatible) + `append` + `anchor` (`after`/`before`/`replace-block`). Lives in `scripts/lib/contribution.sh`, wired into `scripts/build-patterns.sh` (version overrides + addon patterns) AND `scripts/install.sh` (addon skills/agents). Remaining: `merge`/`patch` modes; anchors added to base files. Supersedes the replace-only mechanism in [architecture.md](./architecture.md).

## Implementation status

| Piece | Status |
|-------|--------|
| `contrib_apply` lib (replace/append/anchor) | ✅ `scripts/lib/contribution.sh` |
| Pattern version overrides via modes | ✅ `build-patterns.sh` `resolve_and_copy` (base → override-by-mode) |
| Addon pattern contributions via modes | ✅ `build-patterns.sh` `merge_addon_patterns` |
| Loud-fail: missing anchor / unknown mode | ✅ |
| Regression harness | ✅ `scripts/test-contribution.sh` (33 assertions, all green) |
| `merge` (frontmatter / table rows) | ⬜ not yet (errors if used) |
| `patch` (gated, `expected:`) | ⬜ not yet (errors if used) |
| Skill/agent contributions (`install.sh`) | ✅ `install.sh` addon copy applies by mode; reversal restores cleanly |
| Anchors (`<!-- bench:anchor:NAME -->`) in base files | ⬜ added on demand |

Backward compatibility: a contribution with **no `mode:`** key is treated as `replace`, so every existing override + addon file keeps working unchanged.

---

How version overrides and addons contribute to base files. Today there is exactly one mode — **replace the whole file** (path shadowing). This spec generalizes that to a small set of robust *contribution modes* so that a contributor can add a section, insert a row, or merge frontmatter **without forking the entire base file**.

---

## 1. Why

The replace-only model has two costs:

1. **Small contributions require full forks.** For `bench-laravel-boost` to add one line ("use the Boost MCP for schema lookups") to every agent, it must ship a complete copy of each agent — ~30 forks for ~30 one-liners. The forks drift from base the moment base changes.
2. **Version overrides duplicate unchanged content.** `overrides/laravel-12/services/SERVICE-002.md` re-ships the whole pattern to express one difference (no pipe operator). The `base-hash` staleness check exists precisely because these forks drift.

A contributor should be able to say "**append this**", "**insert this here**", or "**merge this frontmatter**" — and only reach for a full replace when the file is fundamentally different.

---

## 2. Contribution modes

Ordered by robustness (how well they survive base-file edits):

| Mode | Effect | Depends on base content? | Use for |
|------|--------|--------------------------|---------|
| `append` | Body appended as a trailing section | No | Add a section: a Boost-MCP note, an L12 caveat, an extra "When to Use" block |
| `anchor` | Body inserted at a named marker in the base | Only the anchor name (a stable contract) | Mid-file inject: a Pattern-Lookup table row, a Key-Points bullet |
| `merge` | Structured merge of a known region (frontmatter YAML, a markdown table, a bullet list) | The region's structure, not its text | `tools:` frontmatter, Pattern Lookup tables |
| `replace` | Whole file replaced (current behavior) | No (ignores base) | The file is fundamentally different |
| `patch` | Find/replace declared text (escape hatch) | **Yes — exact text match** | Last resort; must be gated (§6) |

**Primary pair: `append` + `replace`.** They cover ~90% and are both robust (neither matches base text). `anchor` and `merge` handle precise mid-file needs. `patch` is a gated escape hatch, never the default.

Explicitly **out of scope:** a general scripting/manipulation DSL. Anchors + append + merge cover the real needs without a Turing-complete patch language and its maintenance burden.

---

## 3. Contribution file format

A contribution is a markdown file with frontmatter declaring its target and mode. It lives in the contributor's tree mirroring the target path under a `contributions/` (addon) or `overrides/` (version) root.

```markdown
---
target: agents/laravel/model.md      # base-relative path being contributed to
mode: append                          # append | anchor | merge | replace | patch
# --- mode-specific keys ---
anchor: pattern-lookup                # (anchor) the marker name to insert at
position: after                       # (anchor) before | after | replace-block
region: frontmatter.tools             # (merge) what structured region to merge
expected: "..."                       # (patch) the exact base text to replace — drift guard
order: 50                             # optional; lower runs earlier when several target one file
---

<the contribution body>
```

- `mode: replace` needs only `target` (it's today's behavior).
- `mode: append` needs only `target` + body.
- Multiple files may target the same base file; they apply in `order` (then by contributor precedence, §5).

### Anchors in base files

`anchor` mode requires the base file to carry named markers — an explicit, versioned contract:

```markdown
## Pattern Lookup

<!-- bench:anchor:pattern-lookup -->
| Need | Read |
|------|------|
| ... | ... |
<!-- bench:/anchor:pattern-lookup -->
```

- `position: after` / `before` → insert relative to the marker.
- `position: replace-block` → replace everything between the paired `bench:anchor` / `bench:/anchor` markers.
- Anchor names are part of the base file's public surface — renaming one is a breaking change for contributors (treat like an API).

---

## 4. Resolution order (per base file)

The build composes one output file per target, in this order:

```
1. base                        patterns/laravel/base/{file}   (or skills/agents source)
2. version overrides           overrides/laravel-{L}/, overrides/php-{P}/, combined
3. addon contributions         each registered addon's contributions/, in addon-registration order
```

Within a stage, multiple contributions to the same file apply by `order` then registration order. `replace` at any stage discards everything composed so far for that file and starts a fresh base for later stages (a later append still appends to the replacement).

This generalizes the current pipeline (base → version override → addon merge) — the only change is that each layer can now contribute via any mode, not just `replace`.

---

## 5. Conflict handling

- **Append/anchor/merge never hard-conflict** — they compose. Two addons appending both sections both land (in order). Determinism comes from `order` + registration order.
- **`replace` is exclusive** — last `replace` wins and is logged. Two addons both replacing the same file is a warning (the later silently wins today; the build should surface it).
- **`patch` conflicts loudly** — if its `expected:` text isn't found (base drift, or an earlier contribution already changed it), the build **fails** for that file with a clear message. Never silently skip.
- The build emits a per-file **contribution manifest** (which contributors touched which file, in what order) for debuggability.

---

## 6. Validation (drift safety)

- `patch` MUST declare `expected:` (the exact text being replaced). Build fails if not found → no silent breakage.
- `anchor` MUST resolve its marker name in the (post-prior-stages) base. Build fails on a missing anchor.
- `validate-overrides.sh` evolves: `replace`-mode version overrides still carry `base-hash` (unchanged). `append`/`anchor`/`merge` contributions are inherently drift-resilient and don't need a base-hash — which is the point (most version overrides should migrate off `replace`, shrinking the staleness surface).

---

## 7. How this changes existing layers

**Version overrides** — many `overrides/laravel-12/` files become `append` or `anchor` instead of full forks:
- SERVICE-002 (no pipe operator): an `anchor: php-version-note` insert, or an `append` caveat, instead of re-shipping 220 lines.
- This also resolves the **agent version-leak** cleanly: base agents name **no** version-specific syntax (the invariant — patterns are the only version-aware layer); when an L12 project builds, the L12 layer *appends* the rollback note (`use $tries, not #[Tries]`). The version-specific text only exists when the version layer contributes it.

**Addons** — `bench-laravel-boost` ships `contributions/agents/laravel/*.md` with `mode: append` (one short Boost-MCP section per agent) instead of forking each agent. The staged addons (`laravel-ai`, `laravel-swagger`, `laravel-query-builder`, `laravel-public-id`, `laravel-boost`, `laravel-ci`, `tdd`) should be **authored against this system**, not as forks.

**Compact profile** is independent of this — it filters which *skills* install; orthogonal to how files are composed.

---

## 8. Build-pipeline impact

`scripts/build-patterns.sh` (patterns) and the install's addon-merge pass (skills/agents) gain a **composer** step:

1. For each target, gather all contributions (base + version + addons).
2. Sort by stage, then `order`, then registration.
3. Apply each by mode (append concat, anchor splice, merge structured, replace reset, patch guarded find/replace).
4. Emit the composed file + a contribution manifest.
5. Fail loudly on unresolved anchors / missing `expected:` text.

The `<PLUGIN_ROOT>` substitution and frontmatter handling stay as they are.

---

## 9. Open questions

- **`merge` scope:** start with just `frontmatter` (YAML) + `markdown-table-rows`? Those are the concrete needs; defer arbitrary structured merge.
- **Anchor coverage:** which base files get anchors, and which names? Probably just `pattern-lookup` and `key-points` initially, added on demand.
- **Ordering UX:** is a numeric `order` enough, or do contributors need named phases? Start numeric.
- **Per-mode authoring ergonomics:** a `bench addon add-contribution` helper that scaffolds the frontmatter?

## 10. Non-goals

- A general text-manipulation/scripting DSL (sed-like programs in frontmatter). `patch` is the only text-level mode and it's a gated escape hatch.
- Changing the compact-profile mechanism (separate concern).
- Changing pattern *versioning* (stays `base` + rollback overrides — this spec only changes *how* an override contributes, not the base/override model itself).
