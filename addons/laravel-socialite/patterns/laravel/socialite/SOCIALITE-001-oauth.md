# SOCIALITE-001-oauth

## Pattern

Laravel Socialite wraps OAuth1/OAuth2 to let users sign in with an external provider (Google, GitHub, GitLab, Bitbucket, etc.). The flow is two routes per provider: a **redirect** that sends the user to the provider, and a **callback** that the provider returns to with an authorization `code`. The callback exchanges the code for the provider's user, maps it to a local `User`, and logs them in.

Use it for social login / account linking. It is not a full identity solution on its own — you still own the local `User` record and session.

## Setup

```bash
composer require laravel/socialite
```

Each provider needs credentials in `config/services.php` (values from `.env`):

```php
// config/services.php
'github' => [
    'client_id'     => env('GITHUB_CLIENT_ID'),
    'client_secret' => env('GITHUB_CLIENT_SECRET'),
    'redirect'      => env('GITHUB_REDIRECT_URI'),   // must match the provider app's callback URL
],
```

## Routes

Two routes per provider — a redirect and a callback:

```php
// routes/web.php
use App\Http\Controllers\Auth\OAuthController;

Route::get('/auth/{provider}/redirect', [OAuthController::class, 'redirect'])
    ->name('oauth.redirect');
Route::get('/auth/{provider}/callback', [OAuthController::class, 'callback'])
    ->name('oauth.callback');
```

Constrain `{provider}` to the providers you actually support (in the controller or a route pattern) so arbitrary driver names can't be passed.

## Redirect + callback controller

```php
<?php

declare(strict_types=1);

namespace App\Http\Controllers\Auth;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\RedirectResponse;
use Illuminate\Support\Facades\Auth;
use Laravel\Socialite\Facades\Socialite;
use Laravel\Socialite\Two\InvalidStateException;

class OAuthController extends Controller
{
    private const PROVIDERS = ['github', 'google'];

    public function redirect(string $provider): RedirectResponse
    {
        abort_unless(in_array($provider, self::PROVIDERS, true), 404);

        return Socialite::driver($provider)
            ->scopes(['user:email'])
            ->redirect();
    }

    public function callback(string $provider): RedirectResponse
    {
        abort_unless(in_array($provider, self::PROVIDERS, true), 404);

        try {
            $oauthUser = Socialite::driver($provider)->user();
        } catch (InvalidStateException) {
            // State mismatch — expired session or CSRF. Restart the flow.
            return redirect()->route('login')->withErrors([
                'oauth' => 'The sign-in attempt expired. Please try again.',
            ]);
        }

        $user = User::query()->updateOrCreate(
            [
                'oauth_provider' => $provider,
                'oauth_id'       => $oauthUser->getId(),
            ],
            [
                'name'   => $oauthUser->getName() ?? $oauthUser->getNickname(),
                'email'  => $oauthUser->getEmail(),
                'avatar' => $oauthUser->getAvatar(),
            ],
        );

        Auth::login($user, remember: true);

        return redirect()->intended(route('dashboard'));
    }
}
```

## Mapping the provider user to a local User

The provider user exposes `getId()`, `getName()`, `getNickname()`, `getEmail()`, `getAvatar()`, plus `token` / `refreshToken`. Map on a **stable provider id**, not email (emails change; ids don't):

- Store `oauth_provider` + `oauth_id` columns on `users` (or a separate `social_accounts` table — see Linking).
- `updateOrCreate` keyed on `(oauth_provider, oauth_id)` makes login idempotent: first time creates, later logins refresh profile fields.
- Some providers (e.g. GitHub without the `user:email` scope) return a null email. Request the email scope, and decide a fallback (prompt for email, or reject) when it's still null.

If your `users` table requires a `password`, make it nullable for OAuth-only accounts, and gate password-login routes accordingly.

## Linking accounts

One user may sign in with several providers, or link a social account to an existing password account. Model this with a dedicated table rather than columns on `users`:

```php
// social_accounts: id, user_id, provider, provider_id, ...  unique(provider, provider_id)
```

- In `callback`, if a `social_account` exists for `(provider, provider_id)`, log in its user.
- Else if a `User` exists with the verified provider email **and** the request is an authenticated "link" action, attach a new `social_account` to that user.
- Else create a new `User` + `social_account`.

Only auto-merge on email when the provider asserts the email is verified — otherwise treat a matching email as a new account to avoid account-takeover.

## Stateless API usage

The session-based flow relies on the OAuth `state` parameter for CSRF protection. For SPAs / token APIs with no session, use stateless mode — but then **you** must carry CSRF protection another way (e.g. a signed `state` you generate and verify):

```php
return Socialite::driver($provider)->stateless()->redirect();
// ...
$oauthUser = Socialite::driver($provider)->stateless()->user();
```

In stateless mode `InvalidStateException` is not thrown, so add your own anti-CSRF check. After mapping the user, issue your API token (e.g. Sanctum) instead of `Auth::login()`.

## Securing the callback

- **Validate state** — keep the stateful flow (default) so Socialite enforces the OAuth `state`; catch `InvalidStateException` and restart rather than 500.
- **Whitelist providers** — `abort_unless(in_array($provider, self::PROVIDERS, true), 404)` so unknown drivers can't be instantiated.
- **Exact redirect URIs** — the `redirect` in `config/services.php` must match the provider app's registered callback exactly (scheme + host + path); use HTTPS in production.
- **Verified email only** for auto-linking; never trust an unverified provider email to claim an existing account.
- **Keep secrets in `.env`** — never commit `client_secret`.
- **Regenerate the session** after login (`Auth::login` + `$request->session()->regenerate()` in the session flow) to prevent fixation.

## Testing

Socialite ships a fake for feature tests:

```php
Socialite::fake('google', [
    'id'    => '9876543210',
    'name'  => 'Jane Doe',
    'email' => 'jane@example.com',
]);

$this->get('/auth/google/callback?code=fake&state=fake');

$this->assertDatabaseHas('users', ['email' => 'jane@example.com']);
$this->assertAuthenticated();
```

## Key Points

- Two routes per provider: redirect → provider, callback → exchange code + map user.
- Map on the stable provider id (`oauth_id`), not email; `updateOrCreate` keeps login idempotent.
- Catch `InvalidStateException` and restart the flow — never let it 500.
- Whitelist supported providers; keep redirect URIs exact and secrets in `.env`.
- Use `->stateless()` for token APIs, but add your own CSRF protection and issue an API token instead of a session login.
- Model multi-provider linking with a `social_accounts` table; auto-merge on email only when verified.
