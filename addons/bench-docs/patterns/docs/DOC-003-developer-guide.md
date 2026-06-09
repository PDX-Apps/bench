# Developer guide — structure

A developer guide explains **how a part of the codebase works so another developer can use or extend it** — its purpose, its public surface, and the seams you build against. It can be **technical** (interfaces, contracts, types, extension points) — that's the point. What it is **not**: it's not an ADR (it doesn't argue a *decision* with context/alternatives/consequences), and it's not an implementation plan (it doesn't lay out ordered steps to build something). It documents the thing as it exists, for the next developer.

## When to write one

- A subsystem with an **extension seam** — an interface/abstract others implement (e.g. a `ReportGenerator` with four required methods, a driver/adapter contract, a plugin hook).
- A module with a **public API for other code** — services, facades, events others subscribe to — where "how do I call this correctly" isn't obvious from the signatures alone.
- A non-trivial **mechanism** a developer must understand before touching it (a pipeline, a lifecycle, a caching/invalidation scheme).

If the code is self-explanatory from its names and a README, you don't need one.

## Ground it in the real code

Every contract, method, type, and example must come from code you read — the interface file, its implementations, the call sites. Quote real signatures and real paths. If you describe "implement these four methods", they are the actual four methods on the actual interface, copied accurately.

## Structure

```markdown
# {Subsystem / module} — developer guide

{1–2 sentences: what this subsystem does and why a developer would touch it.}

## Concepts

{The handful of ideas a reader needs first — the key abstraction(s) and how
they relate. Short. Name the real types.}

## The contract

{The public surface a consumer/implementer builds against — the interface(s),
required methods, expected inputs/outputs, and invariants. Use the real
signatures.}

```{lang}
interface ReportGenerator {
    // real methods, copied from the source
}
```

| Member | Responsibility |
|--------|----------------|
| `generate(...)` | {what an implementation must do} |

## Extending it

{The steps to add a new implementation/driver/handler: create the class,
implement the contract, register/wire it (where + how), and what to expect.
Concrete, with the real registration point.}

## Usage

{How a consumer calls it — the common path, with a real example drawn from an
existing call site.}

## Gotchas

{Real constraints: ordering, side effects, thread/queue concerns, what NOT to
do. Only real ones. Omit if none.}

## Key files

- `app/...` — {role}
```

## Conventions

- **For developers** — technical depth is welcome; assume the reader codes in this stack. Still skimmable: lead with concepts, then the contract.
- **Grounded** — every signature, type, path, and registration step verified against the code. Mark anything you couldn't confirm as an open question, don't invent it.
- **Documents, doesn't decide or plan** — describe how it works and how to extend it. If you find yourself arguing *why this design over another*, that's an ADR (bench-plan); if you're listing steps to *build a new feature*, that's a plan (bench-plan).
- **Maintainable** — point at the real interface/implementation files (`Key files`) so the guide has a source of truth to re-check against as the code evolves.
