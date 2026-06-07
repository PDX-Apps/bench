---
description: Generate a Laravel trait (Has*, InteractsWith*, Can*, Handles*) for behavior reused across 3+ classes — model, controller, or test traits. Use whenever the user mentions a trait, mixin, shared behavior, or extracting common logic.
argument-hint: [what the user needs]
---

You're the **/trait** skill. Translate the user's trait request into an enriched delegation to the `trait` agent.

The user's request: **$ARGUMENTS**

## Step 1: Parse

Extract:
- **Trait name** — `Has{Thing}` | `InteractsWith{Thing}` | `Can{Action}` | `Handles{Thing}` (`HasReference`, `HandlesApiResponses`, `InteractsWithOrders`)
- **Kind** — model trait | controller trait | test trait
- **What it adds** — properties, methods, boot logic, scopes
- **Classes that will use it** — should be 3+ to justify a trait

## Step 2: Resolve Ambiguity

- < 3 usages → push back: "Traits are for 3+ usages. Inline the behavior in 2 classes, or proceed anyway?"
- Boot logic needed → use the `boot{TraitName}()` convention
- Test trait → reads the test-traits pattern (mock/stub helpers)

## Step 3: Build Context Blob

```
Context for trait agent:
- Trait name: {Has|InteractsWith|Can|Handles}{Thing}
- Kind: model | controller | test
- Adds: [properties, methods, boot logic, scopes]
- Boot method: boot{Name}(): void  (if needed)
- Will be used by: [Order, Subscription, Invoice]
```

## Step 4: Delegate

Task tool, `subagent_type: "trait"`, pass the blob.

## Step 5: Synthesize

Report the trait path, what it adds (properties/methods/boot/scopes), and that it should be applied to its 3+ target classes (suggest as a follow-up).

## When to Ask vs Assume

- Naming convention → enforce `Has*`, `InteractsWith*`, `Can*`, `Handles*`
- Boot method `boot{TraitName}()` → standard Laravel convention
- Location → `Concerns/` within the relevant namespace
