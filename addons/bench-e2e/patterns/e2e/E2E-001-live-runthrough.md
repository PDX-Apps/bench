# Acceptance-criteria run-through — conventions

How to *verify a ticket's acceptance criteria* in a real browser via a browser MCP and report on it. This is **live verification**, not test authoring — no `.spec` is written to disk. (To author a reusable Playwright spec, use playwright's `/playwright`.)

## Preconditions

- A **browser MCP must be connected**. For the Chrome driver, check `list_connected_browsers` first; if nothing is connected, stop and ask for it. For the Playwright driver, the Playwright MCP must be available.
- The **acceptance criteria** for the ticket/flow (what "done" means), a concrete **start URL** (not just a route), and any inputs.

## Pre-steps — derive the run from the criteria

Before touching the browser, run the configured `pre_steps`. The default first step:

- **Read the acceptance criteria** and turn each into a checkable step with an **expected outcome**. The criteria are the contract — the run exists to give every one a verdict.
- Then any project pre-steps (seed a user, set a feature flag, choose an environment).

## Drive the flow

- Locate elements (`find` / `read_page`, or the Playwright driver's snapshot/locator), then act (`computer` click/type, or Playwright click/fill). Prefer visible labels/roles over guessed coordinates.
- One step at a time; confirm the page reacted before moving on. No fixed sleeps — read the page to confirm readiness.
- Take a baseline frame right after navigating, and a fresh frame after **each meaningful action** — the before/after pair is the evidence a step did what the criterion expects.

## Capture evidence

Honor the project's capture settings:

- **Screenshots** (when on) — capture one at each meaningful step; reference it in the report so a reviewer can see the state.
- **Console** — after each meaningful step, drain `read_console_messages` and record any **errors/warnings**. Console errors often explain a flow that "looks" fine but is broken underneath.
- **Network** (when on) — inspect `read_network_requests` for **failed / 4xx / 5xx** calls; a criterion can pass visually while a request silently failed.
- **GIF** (when on) — assemble the run's frames into a GIF as a shareable record of the whole journey.

## Don't trigger native dialogs

- Avoid actions that open native browser dialogs the MCP can't safely handle: file pickers, `window.confirm` / `alert` / `beforeunload`, and downloads.
- If the flow would hit one, **stop at that boundary and report it** rather than forcing through it.

## Post-steps — curate the result

Run the configured `post_steps`. The default is the pass/fail-per-criterion report:

```
Ticket/flow: {name}   Start: {url}   Driver: {chrome|playwright}

Acceptance criteria:
- [pass]    {criterion} — evidence: step 3, observed {y} (screenshot 3)
- [fail]    {criterion} — expected {x}, observed {y} (screenshot 5)
- [blocked] {criterion} — {why: element missing / dialog boundary / not reached}

Steps:
1. {action} → expected {x} / observed {y}  [ok | mismatch]
2. ...

Console: {errors/warnings, or "clean"}
Network: {failed / 4xx / 5xx calls, or "clean" / "not captured"}
Artifacts: {GIF path; screenshot references}
Note: no test file written. For a durable regression test, use playwright's /playwright.
```

## Conventions

- **Verify against the stated criteria** — every acceptance criterion gets a pass / fail / blocked verdict.
- **Verification only** — never write product or test files. Screenshots and the GIF are evidence artifacts, not code.
- **Evidence over assertion** — cite real observed state from frames, console, and network.
- **Fail honestly** — if a step or criterion can't be reached (element missing, dialog boundary, MCP not connected), say so and where; don't fabricate a pass.
