---
description: Configure Laravel auth setup — Sanctum, session, AuthService injection refactor, web/API auth wiring. Rare; most auth work is policies (use /policy instead).
argument-hint: [what the user needs]
---

You're the **/auth-config** skill. Translate the user's auth-configuration request into an enriched delegation to the `auth-config` agent. Most authorization work uses `/policy` — this skill is for framework-level setup.

The user's request: **$ARGUMENTS**

## Step 1: Parse

Extract:
- **Type of work**:
  - `sanctum` — install/configure Sanctum for API auth
  - `web` — session-based web auth setup
  - `auth-service` — refactor to inject `AuthService` instead of `auth()->id()`
  - `guard` — custom guard configuration
- **Scope**: specific module or app-wide

## Step 2: Inspect

```bash
ls config/auth.php 2>/dev/null
ls config/sanctum.php 2>/dev/null
ls bootstrap/app.php 2>/dev/null
grep -rln "auth()->id()\|auth()->user()" Modules/ --include="*.php" 2>/dev/null | head -10  # for refactor
```

## Step 3: Resolve Ambiguity

- "Authorization for X" → redirect to `/policy`
- AuthService refactor scope → ask "All modules or one specific module?" (these are big changes)
- Already-configured items → don't re-do; report current state

## Step 4: Build Context Blob

```
Context for auth-config agent:
- Type: sanctum | web | auth-service | guard
- Scope: app-wide | module {Name}
- Current state observed: [Sanctum installed yes/no, AuthService usage frequency]
- Files to update: [config/auth.php, bootstrap/app.php, ...]
- For auth-service refactor: list of files using auth()->id() that need rewrite
```

## Step 5: Delegate

Task tool, `subagent_type: "bench:auth-config"`, pass the blob.

## Step 6: Synthesize

> "Configured Sanctum for API auth: `config/sanctum.php`, route middleware `auth:sanctum` on `routes/api.php`. AuthService bound in `bootstrap/app.php`. Tests still passing."

## When to Ask vs Assume

- "Authorize this controller" → redirect to /policy
- AuthService refactor → big diff; ask scope
- Sanctum vs Passport → always Sanctum (project default)
