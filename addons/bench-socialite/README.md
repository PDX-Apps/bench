# bench-socialite

Laravel **Socialite** OAuth social login — "sign in with Google/GitHub", mapping the provider user to a local account, linking accounts, and stateless API usage.

## What it ships

- **`SOCIALITE-001-oauth`** pattern — the redirect/callback flow, mapping a provider user to a local `User` (keyed on a stable provider id), account linking via a `social_accounts` table, stateless usage for token APIs, securing the callback (state validation, provider whitelist, exact redirect URIs), and testing with `Socialite::fake()`.
- **`/socialite`** skill + **`socialite`** agent — scaffold the redirect + callback controller, routes, and `config/services.php` block for one or more providers.

## Install

```bash
bench addon add /path/to/bench/addons/bench-socialite
bench rebuild
```

Then `/socialite sign in with GitHub and Google, link by oauth_id`.
