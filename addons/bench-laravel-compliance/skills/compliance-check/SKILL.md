---
description: Review a model or feature for PII, audit-logging, and data-retention compliance gaps. Use when the user mentions PII, sensitive/personal data, GDPR, encryption at rest, audit trail, data retention, right to be forgotten, or asks whether a model handles sensitive data safely.
argument-hint: [model or feature to review]
---

You're the **/compliance-check** skill. Turn the request into an enriched delegation to the `compliance-check` agent. You don't review files yourself.

The user's request: **$ARGUMENTS**

## Step 1: Parse
- What's under review — a specific model, a controller/feature, or a whole module?
- Any stated regime (GDPR, HIPAA, PCI) or data class the user already named.

## Step 2: Resolve
- Target missing/ambiguous → ask which model or feature to review.
- If the user only says "check compliance," default to the model(s) the feature touches and say so.

## Step 3: Build context blob
```
- Review target: {Model|Feature|Module}
- Concerns to weigh: PII handling, audit logging, retention/erasure
- Known regime (if any): {GDPR|HIPAA|PCI|none stated}
- Match the project's layout when locating files
```

## Step 4: Delegate
Task tool, `subagent_type: "compliance-check"`, pass the blob.

## Step 5: Synthesize
Relay the agent's gap report: per-area (PII / audit / retention) findings, each marked ok / gap / N-A, with concrete remediations. This is a **review**, not a code change — only generate fixes if the user then asks.
