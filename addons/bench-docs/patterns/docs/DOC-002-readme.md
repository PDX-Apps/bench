# README / feature doc — structure

A README answers, fast: **what is this, how do I run it, how do I use it, where's the important code.** Optimize for skimming — a reader should orient in under a minute. Same shape works for a whole project, a module/feature, or an API doc (with the usage section focused on endpoints).

## Structure

```markdown
# {Name}

{1–2 sentences: what this is and the problem it solves. No preamble.}

## Setup

{Only the steps needed to get it running — install, env/config, migrations,
the run command. Real commands. Skip anything obvious for the stack.}

## Usage

{The common things a user/dev does, with concrete examples.
For an API: the endpoints/operations — method, path, params,
request/response shape, auth, errors — read from the real handlers.}

## Key files

{The few paths that matter, each with a one-line role — so a reader knows
where to look next.}
- `app/...` — {role}
- `src/...` — {role}

## Notes

{Gotchas, constraints, links to deeper docs/ADRs. Optional — only if real.}
```

## Conventions

- **Lead with what it is** — no throat-clearing, no history lesson.
- **Skimmable** — short sections, lists over prose, real commands and paths.
- **Grounded** — every command, endpoint, and path is verified against the code, not assumed.
- **Right altitude** — a feature README documents that feature; don't restate the whole project.
- **Maintainable** — prefer pointing at the code (`Key files`) over copying code that will drift.
- For **API docs**, make `Usage` the core: one entry per endpoint/operation with its contract, drawn from the actual routes/handlers/types.
