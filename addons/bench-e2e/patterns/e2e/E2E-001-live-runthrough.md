# Live MCP run-through — conventions

How to *exercise* a user flow in a real browser via the Chrome MCP and report on it. This is **exploratory verification**, not test authoring — nothing is written to disk. (To author a reusable Playwright `.spec`, use bench-playwright's `/e2e`.)

## Preconditions

- The **Chrome MCP (claude-in-chrome) must be connected**. Check `list_connected_browsers` first; if nothing is connected, stop and ask for it — the run can't proceed.
- A concrete **start URL** (not just a route) and the **expected outcome** of the flow.

## Capture before/after frames

- Take a baseline frame (`read_page`) right after navigating to the start URL.
- After **each meaningful action** (click, type, submit), capture a fresh frame. The before/after pair is the evidence that the step did what was expected.
- Report from what the frame actually shows — real on-page text and state — never from assumption.

## Drive the flow

- Locate elements with `find` / `read_page`, then act with `computer` (click, type). Prefer visible labels/roles over guessed coordinates.
- One step at a time; confirm the page reacted before moving on. No fixed sleeps — read the page to confirm readiness.

## Check the console

- After each meaningful step, drain `read_console_messages` and record any **errors or warnings**. Console errors often explain a flow that "looks" fine but is broken underneath.

## Don't trigger native dialogs

- Avoid actions that open native browser dialogs the MCP can't safely handle: file pickers, `window.confirm` / `alert` / `beforeunload`, and downloads.
- If the flow would hit one, **stop at that boundary and report it** rather than forcing through it.

## Report observed vs expected

For each step record: the action taken, what was **expected**, what was **observed**. Then an overall verdict:

```
Flow: {name}   Start: {url}

1. {action} → expected {x} / observed {y}  [ok | mismatch]
2. ...

Result: {reached expected outcome? where it broke}
Console: {errors/warnings, or "clean"}
Note: no file written. For a durable regression test, use bench-playwright's /e2e.
```

## Conventions

- **Verification only** — never write product or test files.
- **Evidence over assertion** — cite real observed state from frames.
- **Fail honestly** — if a step can't be completed (element missing, dialog boundary, MCP not connected), say so and where; don't fabricate a pass.
