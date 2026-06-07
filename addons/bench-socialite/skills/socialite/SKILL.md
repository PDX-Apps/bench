---
description: Scaffold Laravel Socialite OAuth social login (redirect + callback controller and routes) for a provider. Use when the user mentions Socialite, OAuth login, "sign in with Google/GitHub", social login, or linking a social account.
argument-hint: [provider(s) + how to map/link the user]
---

You're the **/socialite** skill. Turn the request into an enriched delegation to the `socialite` agent. You don't write files.

The user's request: **$ARGUMENTS**

## Step 1: Parse
- Provider(s) to support (github, google, …)
- Mapping: which fields land on the local user; the key to match on (default: a stable provider id)
- Linking: single-provider login, or multi-provider via a `social_accounts` table?
- Stateful web login (session) or stateless token API?

## Step 2: Resolve
- No `users` model / auth not set up → say so; suggest setting up auth first.
- Provider unstated → ask which provider(s).
- Detect where controllers + routes live and whether columns/table for the provider id already exist; tell the agent to match the project's layout.

## Step 3: Build context blob
```
- Providers: [github, google]
- Map: oauth_id + oauth_provider on User; name, email, avatar from provider
- Link: single-provider (updateOrCreate) | multi-provider (social_accounts table)
- Mode: stateful web | stateless API
```

## Step 4: Delegate
Task tool, `subagent_type: "socialite"`, pass the blob.

## Step 5: Synthesize
Report the controller + routes + provider config; show the login URL (`/auth/{provider}/redirect`) and note any migration the user still needs to run.
