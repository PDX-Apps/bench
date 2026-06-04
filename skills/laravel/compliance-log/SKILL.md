---
description: Audit and fix PII/compliance issues in Laravel logging — hash PII before logging, separate audit logs, never log PII in exceptions. Per DATA-001.
argument-hint: [what the user needs]
---

You're the **/compliance-log** skill. Translate the user's compliance request into an enriched delegation to the `compliance-log` agent.

The user's request: **$ARGUMENTS**

## Step 1: Parse

Extract:
- **Module** (or all)
- **Audit scope**: specific files | module sweep
- **PII types of concern**: email, phone, name, IP, address — usually all

## Step 2: Inspect

```bash
ls Modules/{Module}/ 2>/dev/null || echo "MODULE_MISSING"
# Find Log:: calls with potential PII
grep -rn "Log::" Modules/{Module}/ --include="*.php" 2>/dev/null | grep -iE "email|phone|name|address|ip" | head -20
# Find exception messages with PII
grep -rn "throw new" Modules/{Module}/ --include="*.php" 2>/dev/null | grep -iE "email|phone|name" | head -10
```

## Step 3: Resolve Ambiguity

- Scope → confirm: "Sweep `Modules/{Module}/` or specific files?"
- Found violations → list them; ask "Fix all OR review one by one?"

## Step 4: Build Context Blob

```
Context for compliance-log agent:
- Module: {Module}
- Scope: module-sweep | files {paths}
- Violations found:
    - Modules/Bill/Jobs/BillReminderJob.php:42 — Log::info with raw $user->email
    - Modules/Bill/Policies/BillPolicy.php:15 — exception message contains $user->name
    - Modules/Bill/Actions/MarkBillPaidAction.php:30 — Log::warning with $user->phone
- Hashing pattern: hash('sha256', config('app.key') . $value)
- Audit log channel: 'audit' (separate from 'application')
```

## Step 5: Delegate

Task tool, `subagent_type: "bench:compliance-log"`, pass the blob.

## Step 6: Synthesize

> "Fixed 3 PII compliance issues in `Modules/Bill/`: replaced raw email/name/phone in logs with hashed values via `hash('sha256', config('app.key') . $value)`. Removed PII from exception messages (now just IDs). Audit logs routed to `audit` channel."

## When to Ask vs Assume

- Hash PII before logging → always
- PII in exception messages → NEVER (they get auto-logged)
- Audit channel separation → always (per DATA-001)
- Test changes → suggest follow-up `/feature-test` to confirm logging behavior
