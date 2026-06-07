# Layering — how overrides & addons modify patterns

Bench's patterns live in `base/`. You rarely want to fork a whole pattern just to change one line — so an **override** (your project's `.bench/`, or a version rollback) or an **addon** can target a base file and declare a **mode** that says *how* its content combines with the base. Add a section, splice in a table row, or replace the file outright — without copying the parts you didn't change.

A contribution with **no mode is a full replace**, so "just use my version" needs nothing extra.

---

## The modes

Ordered from most to least robust (how well they survive edits to the base file):

| Mode | What it does | Reach for it when |
|------|--------------|-------------------|
| `append` | Adds the body as a trailing section; the base is untouched. | Adding a note or section — an Octane caveat, an extra "When to use". Upgrade-safe. |
| `anchor` | Splices the body at a named marker in the base. | Injecting mid-file where the base declares an anchor — a Pattern-Lookup row, a key-points bullet. |
| `merge` | Splices your markdown table rows into the base table with the **same header** (found by the header row — no marker needed). | Adding rows to a table the base already has. |
| `replace` | Replaces the whole file; the base is ignored. The default when no mode is set. | The pattern is fundamentally different for your project or version. |
| `patch` | Gated literal find/replace — each `FIND` block must match the base **exactly once**. | A surgical edit to existing prose the other modes can't express. Last resort. |

**Prefer `append` and `replace`** — they don't depend on the base's exact text, so a base update won't break them. `anchor` and `merge` handle precise mid-file edits against a stable contract (a marker name, a table header). `patch` is a gated escape hatch, never the default.

---

## Declaring a contribution

A contribution is a markdown file whose path mirrors the base file it targets — under your project's `.bench/`, an addon's `patterns/` · `skills/` · `agents/`, or a version `overrides/` root. Its frontmatter declares the mode:

```markdown
---
mode: append            # append | anchor | merge | replace | patch
# anchor mode only:
anchor: pattern-lookup  # the marker name to splice at
position: after         # before | after | replace-block
order: 50               # optional — lower applies earlier when several target one file
---

<your content — see the merge/patch body shapes below>
```

- **`replace`** (or no frontmatter at all) — the body becomes the pattern. Nothing else needed.
- **`append`** — the body is added after the base, separated by a blank line.
- **`merge`** — the body is a markdown table (header + separator + your new rows); the rows are inserted into the base table with the matching header:
  ```markdown
  | Need | Read |
  |------|------|
  | New thing | <PLUGIN_ROOT>/patterns-built/.../NEW-001.md |
  ```
- **`patch`** — the body holds one or more gated blocks; each `FIND` must match the base exactly once:
  ```
  <<<<<<< FIND
  ...exact base text...
  =======
  ...replacement...
  >>>>>>> REPLACE
  ```

### Anchors in base files

`anchor` mode needs the base file to carry named markers — an explicit, versioned contract:

```markdown
<!-- bench:anchor:pattern-lookup -->
| Need | Read |
|------|------|
| ... | ... |
<!-- bench:/anchor:pattern-lookup -->
```

- `position: before` / `after` inserts relative to the opening marker.
- `position: replace-block` replaces everything between the paired markers.
- An anchor name is part of the base file's public surface — renaming one breaks any contribution that targets it.

---

## How layers resolve

For each target file, the build composes one output in this order:

1. **base** — `patterns/.../base/{file}` (or the skill/agent source)
2. **version overrides** — `overrides/laravel-{N}/`, `overrides/php-{N}/`
3. **addons** — each registered addon, in load order
4. **your project** — `.bench/`, auto-discovered as a project-local addon, so it gets the last word

Within a layer, multiple contributions to the same file apply by `order`, then load order. A `replace` at any layer resets the composition — later layers still apply *on top of* the replacement (a later `append` appends to your version).

---

## Drift safety

`append`, `anchor`, and `merge` compose cleanly — two addons appending both land, in order. The modes that depend on base text **fail the build loudly** rather than silently misapplying:

- **`anchor`** — fails if the marker name isn't found.
- **`merge`** — fails if no base table has the matching header.
- **`patch`** — fails if a `FIND` matches zero or 2+ times (base drift, or an earlier contribution already changed that text).

Only `replace`-mode version overrides carry a `base-hash` (checked by `bench rebuild`) — a full fork is the one kind that can silently go stale when base moves. The other modes are drift-resilient by design. That's the point: prefer them.
