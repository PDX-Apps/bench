---
description: Generate Laravel custom Eloquent attribute casts. Use whenever the user mentions a custom cast, value object → DB column transformation (like Money, Address, Settings), JSON column casting, or needs typed access to a complex column attribute in a Laravel project.
argument-hint: [what the user needs]
---

You're the **/cast** skill. Translate the user's request for a custom Eloquent cast into an actionable delegation to the `cast` agent.

The user's request: **$ARGUMENTS**

## Step 1: Parse the Request

Extract:
- **Module name** (Currency, Bill, Household, etc.)
- **Cast name** (`MoneyCast`, `AddressCast`, `HouseholdSettingsCast`)
- **Value type being cast** (Money VO, JSON DTO, custom type)
- **Single-column or multi-column** — does the cast back ONE DB column (e.g., JSON settings) or MULTIPLE (e.g., Money = `amount` + `currency`)?
- **Target model(s)** that will use this cast (if user mentioned them)

## Step 2: Inspect the Project

```bash
# Module exists?
ls Modules/{Module}/ 2>/dev/null || echo "MODULE_MISSING"

# Existing casts (naming + structural conventions)
ls Modules/{Module}/app/Casts/ 2>/dev/null

# If multi-column, check the model's columns to know what columns are involved
ls Modules/{Module}/app/Models/ 2>/dev/null
```

## Step 3: Resolve Ambiguity

- Module missing → confirm or suggest `/new-module`
- Single-vs-multi-column unclear → ask one question with examples (e.g., "Single column casting JSON to a DTO, or multi-column like `amount`+`currency`?")
- Value object class exists or needs creating → if needs creating, flag: "Should I create the `{Type}` value object too, or is it provided by a package?"

For obvious cases (user explicitly said "Money cast" → multi-column; "JSON settings" → single-column), skip the question.

## Step 4: Build Context Blob

```
Context for cast agent:
- Module: {Module}
- Cast name: {Name}Cast
- Path: Modules/{Module}/app/Casts/{Name}Cast.php
- Cast type: single-column | multi-column
- Backing column(s): [amount, currency] OR [settings]
- Value object: {Type} (existing | needs-creating | from-package: {package})
- Target model(s): [Bill, Payment]
- Existing cast conventions in module: [MoneyCast uses InvalidArgumentException for unsupported types, etc.]
```

## Step 5: Delegate to the `cast` Agent

Use the Task tool. `subagent_type: "bench:cast"`. Pass the context blob — NOT raw `$ARGUMENTS`.

## Step 6: Synthesize for the User

> "Created `Modules/Bill/app/Casts/MoneyCast.php` — multi-column cast for `amount` (int cents) + `currency` (string code) → `Money` value object. Registered in `Bill` model's `casts()` method. Throws `InvalidArgumentException` for invalid input."

Mention follow-ups (need a migration to add the columns? need to update existing model `casts()` method?).

## When to Ask vs Assume

- **Cast type clear from value object** (Money is always multi-column; JSON settings is always single) → don't ask
- **Casts existing in module** → match their style; don't ask about conventions
- **Model registration** → assume the agent registers in the named model's `casts()` method

## Anti-Patterns

- Passing raw `$ARGUMENTS` to the agent
- Asking for clarification on things obvious from the request
- Forgetting to check existing module casts for naming conventions
