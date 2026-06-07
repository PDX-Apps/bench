---
description: Generate a Laravel FormRequest class for input validation. Use when the user wants ONLY a FormRequest (not the full HTTP stack). For full HTTP layer (controller+request+resource+route), use /laravel instead.
argument-hint: [what the user needs]
---

You're the **/request** skill. Translate the user's FormRequest into an enriched delegation to the `request` agent.

The user's request: **$ARGUMENTS**

## Step 1: Parse

Extract:
- **FormRequest class name** — `{Action}{Model}Request` (e.g., `CreateOrderRequest`, `UpdateInvitationRequest`)
- **Fields + rules** mentioned (`quantity: required|integer|min:1`)
- **Typed object**: should the request emit one? `toDto()` (immutable DTO — the common case, 4+ params or reused) vs `toData()` (mutable Data Object — persisted settings/preferences); or neither for a 1–3 field one-off
- **Custom Rule objects** referenced (e.g., `ValidQuantity`)

## Step 2: Resolve Ambiguity

- Typed object needed? → 4+ params or reused outside this request → `toDto()`; mutable persisted state → `toData()`; otherwise skip (use `validated()`)
- Custom rule referenced that doesn't exist → flag: "Rule `ValidQuantity` doesn't exist. Generate `/rule` first?"

## Step 3: Build Context Blob

```
Context for request agent:
- Class: {Action}{Model}Request
- Fields + rules:
    name: required, string, max:100
    quantity: required, integer, min:1
- Custom Rule objects referenced: [ValidQuantity] (existing | to-be-created)
- Emits: toDto() → {Name}Data | toData() → {Name}Data | none
- Custom error messages: [...]
```

## Step 4: Delegate

Task tool, `subagent_type: "request"`, pass the blob.

## Step 5: Synthesize

Report the FormRequest path, field/rule count, any custom messages, and what it emits (`toDto()`/`toData()`/none).

## When to Ask vs Assume

- Custom error messages → include if the user mentioned UX or for non-obvious rules; otherwise rely on Laravel defaults
- `authorize()` → return `true` (authorization is on the controller via `#[Authorize]`, not the request)
