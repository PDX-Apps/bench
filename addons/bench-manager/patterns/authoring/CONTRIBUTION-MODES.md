# Authoring a `.bench/` contribution — by mode

How project-local overrides under `./.bench/` layer onto Bench's bundled files. Read this before writing any `.bench/` pattern, skill, or agent override. The full design is in the source's `docs/layering.md`; this is the field guide.

A `.bench/` file mirrors the path of the bundled file it contributes to (e.g. `.bench/patterns/laravel/models/MODEL-001-structure.md` layers onto the bundled `MODEL-001-structure`). Its leading frontmatter declares **how** it layers, via `mode:`. **No `mode:` key = `replace`** (legacy full-file fork), so old overrides keep working.

## Pick the lightest mode that does the job

| The project wants to… | Mode | Why |
|------------------------|------|-----|
| **Add** a note/section/convention to a pattern, keeping everything else | `append` | Base stays; you ship only the addition. Survives Bench upgrades. |
| **Insert** into a specific spot (a Pattern-Lookup row, a Key-Point bullet) | `anchor` | Targets a named marker; base stays around it. |
| **Fundamentally change** the file (different structure, contradicts the base) | `replace` | A full fork. Use only when adding/inserting can't express it. |

**Default to `append`.** Reach for `replace` only when the project's way genuinely contradicts the base — because a `replace` fork drifts the moment Bench's base changes, while `append`/`anchor` don't. ("We *also* extend `BaseController`" → append. "Our controllers are nothing like Bench's" → replace.)

## Frontmatter

```markdown
---
mode: append            # append | anchor | replace  (omit = replace)
anchor: pattern-lookup   # (anchor only) the marker name to target
position: after          # (anchor only) after | before | replace-block
---

<the contribution body — for append/anchor this is ONLY the added content,
 not a copy of the base file>
```

- **`append`** — body is added as a trailing section. Write just the new section (e.g. `## Our project's variation\n- …`).
- **`anchor`** — body is spliced at `<!-- bench:anchor:NAME -->` in the base. Only works if the base file carries that marker. `position: replace-block` swaps the content between the paired markers.
- **`replace`** — the whole file. Write the complete pattern; the base is discarded.

## Rules

- **Append/anchor bodies contain ONLY the delta** — never paste the base file and edit it (that's a `replace` in disguise and it drifts).
- **Match the bundled path exactly** so the contribution lands on the right file.
- **Prefer append/anchor over replace** — they're upgrade-safe; replace forks aren't.
- After writing, run `bench rebuild` so the contribution materializes into `patterns-built/`.
- A missing anchor or bad mode **fails the build loudly** — verify the base actually has the marker before using `anchor`.
