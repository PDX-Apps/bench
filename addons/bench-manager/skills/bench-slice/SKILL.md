---
description: |
  Teach Bench one of YOUR domains so it generates that proprietary code as
  cleanly as core Laravel — builds a full skill→agent→pattern slice for a domain
  you point at. Use when the user says "make a slice for app/Reports", "teach
  Bench my Reports domain", "I want a /report command that scaffolds reports like
  core does controllers", "build a skill+agent+pattern for our Sagas", or "scaffold
  Bench support for app/{Domain}". Writes the triple under ./.bench/ (skill +
  paired agent + the domain pattern).
argument-hint: [domain name or path, e.g. "Reports" or "app/Reports"]
---

You're the **/bench-slice** skill. Build a project-local skill→agent→pattern slice for a domain the user names, by orchestrating the three authoring agents. You don't author files yourself — you sequence the authors and relay their output.

The user's request: **$ARGUMENTS**

## Step 1: Identify the domain

- Resolve the domain name + path (e.g. `Reports` → `app/Reports/`). Confirm it exists with a quick `find`/`ls`. If it doesn't exist yet, say so — the slice will be more speculative and the first run needs close review.
- Pick the slug for the slice: `/{domain}` skill, `{domain}` agent, `{Domain}` pattern (e.g. `report` / `report` / `Report`).

## Step 2: CAPTURE the domain pattern (pattern-author)

Delegate first — the pattern is what the agent will read, so it comes first.

```
Task(subagent_type: "pattern-author", description: "Capture {domain} pattern", prompt: """
  intent: capture
  domain: {domain}  (code lives at {path})
  This is the pattern half of a /bench-slice — author a project pattern describing
  how THIS project writes {domain} classes (structure, naming, base classes, the
  full file set per unit, conventions). defer_rebuild: true.
  project_root: {cwd}   bench_install_root: <PLUGIN_ROOT>
""")
```

Keep the returned **findings + pattern path + generation surface** — you pass them forward so the next authors don't re-scan.

## Step 3: Design the skill + agent (skill-author → agent-author)

```
Task(subagent_type: "skill-author", description: "Design /{domain} skill+agent", prompt: """
  intent: new
  name: {domain-slug}
  change_request: a /{domain} command that scaffolds a {Domain} unit + its full
    generation surface, matching this project.
  Generation surface (from pattern-author): {file list}
  Domain pattern to read: {.bench pattern path}
  Hand off to agent-author for the paired {domain-slug} agent; its Pattern Lookup
  points at the domain pattern above. defer_rebuild: true.
  project_root: {cwd}   bench_install_root: <PLUGIN_ROOT>
""")
```

`skill-author` cascades to `agent-author` internally, so this yields both the skill and its agent.

## Step 4: Approve, rebuild once, report

After the user approves all three drafts and they're written, rebuild a single time:

```bash
<PLUGIN_ROOT>/bin/bench rebuild
```

Report the slice:
```
Slice created for {Domain}:
- skill:   .bench/skills/{slug}/SKILL.md
- agent:   .bench/agents/{slug}.md
- pattern: .bench/patterns/{group}/{Domain}-...md
Generation surface: {files one invocation produces}
Try it: /{slug} create {Example}
```

## Notes

- **Sequence matters**: pattern first (the agent reads it), then skill+agent.
- **One rebuild** at the end — pass `defer_rebuild: true` to each author so they don't each rebuild.
- Surface every author's **divergence callouts** to the user; don't bake in a guessed convention silently.
- A slice is project-local under `.bench/`. If it'd serve many projects, suggest promoting it to a standalone addon later.
