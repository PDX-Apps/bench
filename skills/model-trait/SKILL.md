---
description: Generate a Laravel model trait (Has*, InteractsWith*, etc.) for behavior reused across 3+ models. Use whenever the user mentions a trait, mixin, shared model behavior, or extracting common logic from multiple models.
argument-hint: [what the user needs]
---

You're the **/model-trait** skill. Translate the user's trait request into an enriched delegation to the `model-trait` agent.

The user's request: **$ARGUMENTS**

## Step 1: Parse

Extract:
- **Module** (Audit, Bill, etc.) — or Core if shared cross-module
- **Trait name** — `Has{Thing}` | `InteractsWith{Thing}` | `Can{Action}` | `Handles{Thing}` (`HasPublicId`, `Auditable`, `HasJourney`)
- **What it adds** — properties, methods, boot logic, scopes
- **Models that will use it** — should be 3+ to justify a trait

## Step 2: Inspect

```bash
ls Modules/{Module}/ 2>/dev/null || echo "MODULE_MISSING"
ls Modules/{Module}/app/Traits/ 2>/dev/null
grep -rln "use {ProposedTrait}" Modules/ --include="*.php" 2>/dev/null
```

## Step 3: Resolve Ambiguity

- < 3 models → push back: "Traits are for 3+ usages. Inline the behavior in 2 models or proceed anyway?"
- Boot method needed → assume `boot{TraitName}` convention
- Cross-module trait → place in `Modules/Core/` or specific module owning the concept

## Step 4: Build Context Blob

```
Context for model-trait agent:
- Module: {Module}
- Trait name: {Has|InteractsWith|Can|Handles}{Thing}
- Path: Modules/{Module}/app/Traits/{Name}.php  (project uses /Traits/ not /Concerns/)
- Adds: [properties, methods, boot logic]
- Boot method: boot{Name}() : void  (if needed)
- Will be used by: [BillModel, PaymentModel, HouseholdModel]
- Existing siblings: [Auditable.php, HasJourney.php]
```

## Step 5: Delegate

Task tool, `subagent_type: "bench:model-trait"`, pass the blob.

## Step 6: Synthesize

> "Created `Modules/Audit/app/Traits/HasJourney.php`. Boot method registers a `creating` observer. Method `journey()` returns `MorphTo`. Apply via `use HasJourney;` in 3+ target models."

## When to Ask vs Assume

- Naming convention → enforce `Has*`, `InteractsWith*`, `Can*`, `Handles*`
- Boot method `boot{TraitName}()` → standard Laravel convention
- Path: `/Traits/` (project uses this, not `/Concerns/`)
