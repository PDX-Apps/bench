# AUTH-001-web

## Pattern

Session-based authentication via Laravel's default `web` guard. This is the standard Laravel setup — `routes/web.php` carries the application's routes (including blade views AND JSON endpoints when `Route::resource` is used), and authenticated requests carry a session cookie + CSRF token.

This is the default for most Laravel projects. Two common variants exist (captured for a project via the `auth` concern — `/bench-configure auth`):
- **SPA / API-only**: `routes/api.php` only; no web routes. Use Sanctum (AUTH-002) for auth.
- **Web for everything (including API)**: web.php carries both view-returning controllers AND JSON endpoints, all session-authed.

## Config

```php
// config/auth.php
'defaults' => [
    'guard' => env('AUTH_GUARD', 'web'),
    'passwords' => env('AUTH_PASSWORD_BROKER', 'users'),
],

'guards' => [
    'web' => [
        'driver' => 'session',
        'provider' => 'users',
    ],
],
```

## Middleware

Laravel's `web` middleware group (auto-applied to `routes/web.php`) provides:
- Encrypted cookies
- Session start
- CSRF token verification
- Substitute bindings

Authenticated routes wrap with `auth`:

```php
Route::middleware(['auth'])->group(function () {
    Route::resource('orders', OrderController::class);
});
```

`Route::resource` registers all 7 CRUD routes; controller methods can return blade views OR JSON depending on the request (`Accept` header, `expectsJson()`, etc.).

## Login / logout

If using Laravel Breeze, Fortify, or Jetstream, login/logout routes are scaffolded for you. For a manual setup:

```php
Route::post('/login', function (Request $request) {
    $credentials = $request->validate([
        'email' => ['required', 'email'],
        'password' => ['required'],
    ]);

    if (Auth::attempt($credentials, $request->boolean('remember'))) {
        $request->session()->regenerate();

        return redirect()->intended('dashboard');
    }

    return back()->withErrors(['email' => 'Invalid credentials.']);
})->name('login');

Route::post('/logout', function (Request $request) {
    Auth::guard('web')->logout();
    $request->session()->invalidate();
    $request->session()->regenerateToken();

    return redirect('/');
})->name('logout');
```

## Accessing the current user

Inside an HTTP request:
- `$request->user()` — current authenticated user
- `Auth::user()` — same, via facade
- `Auth::id()` — current user ID

For passing the user OUT of HTTP context (into an Action, Job, etc.), see ACTION-001-structure: the controller passes `$request->user()` into the action's `execute(User $user, ...)`.

## When to use

- The project's primary frontend is server-rendered (blade) or hybrid
- Sessions + CSRF are acceptable (typical browser-driven app)
- Mobile / SPA / 3rd-party API consumers will use Sanctum (AUTH-002) on top of this
