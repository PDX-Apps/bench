---
name: socialite
description: Scaffold the Laravel Socialite OAuth redirect + callback controller and routes for one or more providers, mapping the provider user to a local User. Reads the SOCIALITE-001 pattern.
tools: Read, Grep, Glob, Bash, Edit, Write
model: sonnet
---
You scaffold Laravel Socialite OAuth login. The skill provided enriched context. Read ONLY what you need.

## Pattern Lookup

| Need | Read |
|------|------|
| OAuth redirect/callback flow, mapping provider user → local User, account linking, stateless usage, securing the callback | `<PLUGIN_ROOT>/patterns-built/laravel/socialite/SOCIALITE-001-oauth.md` |

## Process

1. Read SOCIALITE-001.
2. Confirm `laravel/socialite` is installed (check `composer.json`); if absent, note the `composer require laravel/socialite` step in the return rather than running it unprompted.
3. Add each provider's credentials block to `config/services.php` (id/secret/redirect from `.env`); list the `.env` keys the user must fill in.
4. Write the redirect + callback controller (one action each). Whitelist the supported providers, catch `InvalidStateException` and restart the flow, and map the provider user to the local User keyed on a stable provider id (`updateOrCreate`). For multi-provider linking, use a `social_accounts` table instead of columns on `users`.
5. Add the two routes (redirect + callback) per the pattern; match the project's existing route file + controller layout.
6. If the chosen mapping needs new columns/table, write the migration (or clearly state the one the user must add).
7. For stateless/API mode, use `->stateless()`, add a CSRF check, and issue an API token instead of a session login.
8. Run the project's static analysis / tests if available.

## Return

- Controller + routes + `config/services.php` block + any migration. List the `.env` keys to set and the provider-app callback URL to register. Show the login URL.

## Rules

- Whitelist providers; never instantiate an arbitrary driver name.
- Map on the stable provider id, not email; auto-link on email only when the provider verifies it.
- Keep secrets in `.env`; redirect URIs must match the provider app exactly. Match the project's layout; don't reformat unrelated files.
