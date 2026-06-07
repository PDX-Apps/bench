# BLADE-005 — Blade → full SPA handoff

When a project is mostly Blade but hands a section (e.g. a dashboard) to a **full** Vue/React SPA, Blade owns the public/auth pages and **one** route boots the SPA. This is the seam between the server-rendered track and the client-rendered track — get these four things right.

## 1. The catch-all route

One Laravel route renders the SPA shell for every sub-path so the client router owns everything below it:

```php
// routes/web.php
Route::view('/app/{any?}', 'spa')->where('any', '.*')->middleware('auth');
```

## 2. The shell Blade view

A minimal view: a single mount node + the bundler entry. No layout chrome the SPA will redraw.

```blade
{{-- resources/views/spa.blade.php --}}
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    @vite('resources/js/app.ts')
</head>
<body>
    <div id="app" data-page="{{ json_encode($bootstrap ?? []) }}"></div>
</body>
</html>
```

## 3. The bootstrap payload

Pass server state the SPA needs at boot — authenticated user, CSRF, runtime config — via a data attribute (read once on mount) or a controller that fills `$bootstrap`. Do **not** make the SPA round-trip for data it could have had at first paint.

```js
// resources/js/app.ts
const el = document.getElementById('app')!
const bootstrap = JSON.parse(el.dataset.page || '{}')
// createApp(App, { bootstrap }).use(router).mount(el)
```

## 4. The client router base path

The client router's base must match the catch-all mount path so deep links resolve:

```js
// createRouter({ history: createWebHistory('/app'), routes })
```

## Notes

- Keep auth/marketing pages as ordinary Blade routes — only the SPA section uses the catch-all.
- The SPA's own page/route/layout/data patterns apply **inside** the SPA section; the rest of the app is Blade (`/blade`).
- This pattern covers the **full-SPA** handoff only. Mounting individual Vue components as islands into otherwise-static Blade pages is left to the project.
