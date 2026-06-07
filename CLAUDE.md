# Bench — Working Context

You are editing the **bench plugin source repo**, not a user's Laravel project. This is the source of bench's skills/agents/patterns/addons. Edits here propagate to users via `bench init` / `bench rebuild`.

## READ FIRST: docs/working-notes/RULES.md

Before editing ANY skill, agent, or pattern file, read [`docs/working-notes/RULES.md`](docs/working-notes/RULES.md). It contains:
- The hard rules the user has repeatedly caught me violating
- All locked decisions from brainstorming sessions
- Pending renames, addon extractions, and refactors
- Pre-edit / post-edit rituals with grep self-checks
- Methodology (depth-first, 3-5 files per batch)

If a context compact has dropped session history, RULES.md is the recovery file.

## Top violations to remember (inline copy of the biggest hits)

These are the rules I keep regressing on. **After every edit, run the matching grep self-check.**

### NO AI attribution in commits/PRs/anything published
`Co-Authored-By: Claude`, `Generated with Claude Code`, 🤖, `noreply@anthropic.com` — never. User has deleted + recreated repos over this.

### NO `/bench-concern` (or any override command) mentions inside skill/agent/pattern bodies
Skills/agents/patterns describe DEFAULTS. Overrides happen invisibly via the precedence stack. The override mechanism is documented in exactly ONE place (the bench-concern skill itself + onboard + /help).

```bash
# After every skill/agent/pattern edit:
grep -E '/bench-concern|/bench-add-' <file> && echo VIOLATION || echo clean
```

### NO auth class names in skill or agent bodies
`AuthFactory`, `auth()`, `auth()->id()`, `Illuminate\Contracts\Auth\Factory` — never in skill or agent body. Only in patterns.

```bash
grep -iE '(AuthFactory|auth\(\)|Illuminate.*Auth.*Factory)' <skill-or-agent-file> && echo VIOLATION || echo clean
```

### NO hardcoded `Modules/` paths in skill/agent bodies
Use placeholders + defer to CLAUDE.md (project's own one) + active addons. The future `bench-laravel-modules` addon handles nwidart projects.

```bash
grep -E 'Modules/' <skill-or-agent-file> && echo VIOLATION || echo clean
```

### NO Bill+Co domain names (Bill, Household, etc.)
Use stack-neutral: Order, Subscription, Invoice, Notification.

### NO commits or pushes without explicit user approval in the CURRENT message
Auto mode does NOT override this.

### Methodology: depth-first, 3-5 files at a time
- Audit + edit ONE skill, then its paired agent, then patterns it reads (vertical slice)
- READ the file completely before editing
- Surface ALL issues + open questions for user BEFORE editing
- Wait for user input on judgment calls

## Pointers

- `docs/working-notes/RULES.md` — the full reference (read on session start)
- `docs/working-notes/full-audit.md` — 131-file audit
- `docs/working-notes/change-log.md` — per-file edit log
- `docs/working-notes.md` — design discussions + future addon ideas
- `/Users/irv/.claude/plans/giggly-drifting-boole.md` — common-concerns implementation plan
