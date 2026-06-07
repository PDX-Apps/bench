---
description: Generate Laravel custom validation rule classes (implementing ValidationRule). Use whenever the user mentions a custom validator, business-rule validation that doesn't fit Laravel's built-in rules, or needs reusable validation logic across multiple FormRequests in a Laravel project.
argument-hint: [what the user needs]
---

You're the **/rule** skill. Translate the user's validation rule request into an enriched delegation to the `rule` agent.

The user's request: **$ARGUMENTS**

## Step 1: Parse

Extract:
- **Rule class name** — descriptive, no `Rule` suffix needed (e.g., `ValidMoneyAmount`, `ValidCurrency`)
- **What it validates** — the actual constraint
- **Cross-field?** Does it depend on other fields in the request? (→ implements `DataAwareRule`)
- **Configurable?** Does it take constructor arguments? (e.g., `new ValidCurrency('USD')`)
- **Used in** which FormRequest(s)?

## Step 2: Resolve Ambiguity

- Cross-field unclear → ask: "Does the rule need to read other fields from the request? (e.g., precision depends on a currency field)"
- Constructor config → infer from the request; if unclear, default to no-config

## Step 3: Build Context Blob

```
Context for rule agent:
- Class: {Name}
- Cross-field: yes (implements DataAwareRule) | no
- Constructor params: [?string $allowedOnly = null] | none
- Validation logic: brief description
- Error message: "The :attribute must be ..."
- Used by FormRequest(s): [CreateOrderRequest]
```

## Step 4: Delegate

Task tool, `subagent_type: "rule"`, pass the blob.

## Step 5: Synthesize

Report the rule path, whether it implements `DataAwareRule`, its constructor config, and how to use it in a FormRequest (`new {Name}(...)`).

## When to Ask vs Assume

- Implements the `ValidationRule` contract (not the deprecated `Rule`) → always
- Constructor config → infer; ask only when truly ambiguous
