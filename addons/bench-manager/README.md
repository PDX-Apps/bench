# bench-manager

The `/bench-*` toolkit for **tailoring Bench to your project**. Bundled by default (`bench init` loads it; opt out with `--no-onboard`). It's how you teach Bench your project's conventions and scaffold your own domains — everything it writes lands in `./.bench/`, your project-local, committable home for overrides and custom slices.

## Commands

| Command | What it does |
|---|---|
| `/bench-init` | First-run setup. Scans your project for where it **deviates** from Bench's defaults (custom base classes, auth/permissions strategy, layout, test framework, response shape) and for proprietary domains worth a slice, then offers to capture each. **Never writes your `CLAUDE.md`.** |
| `/bench-override <change>` | Change a bundled default for this project — a pattern (how code is generated), a skill (how a command behaves), or an agent (how a worker runs). Routes to the right authoring agent, which writes an append / anchor / replace contribution into `.bench/`. |
| `/bench-slice <domain>` | Generate a full **skill → agent → pattern** for one of *your* domains (e.g. `app/Reports/`), so your proprietary code is scaffolded as cleanly as core Laravel. |
| `/bench-list [patterns\|skills\|agents]` | Discover what's available — bundled core, bundled addons, and your project-local extensions. |
| `/bench-show <type> <name>` | View the full body of a pattern / skill / agent before deciding to override it. |
| `/bench-status` | Synthesized health check — versions, profile, project-local overrides, drift, suggested next steps. |

## How it's built (for contributors)

```
agents/               authoring agents (the engine)
  project-scanner     read-only: reports deviations + slice candidates (drives /bench-init)
  pattern-author      authors a project pattern (FORK a default / CAPTURE a convention)
  skill-author        authors a thin-router skill (FORK / NEW + cascades to agent-author)
  agent-author        authors a worker agent (current shape: Pattern Lookup, no read-CLAUDE block)
patterns/authoring/   the methodology the agents follow
  METHODOLOGY-layered-scan   how to understand a codebase efficiently
  CONTRIBUTION-MODES         append / anchor / replace — how a .bench/ file layers onto the base
  RESEARCH-patterns/skills/agents   the per-artifact authoring lenses
skills/               the six /bench-* commands above
```

The two user-facing creators (`/bench-override`, `/bench-slice`) are thin routers; the authoring agents carry the bench-grade knowledge of how to build each artifact type. Output is a project-local contribution under `./.bench/` — auto-discovered on the next `bench rebuild` (no manifest required), so it persists across rebuilds. **Commit `.bench/` with your project.**

See [docs/contribution-system.md](../../docs/contribution-system.md) for the contribution modes and [docs/addons.md](../../docs/addons.md) for the addon contract.
