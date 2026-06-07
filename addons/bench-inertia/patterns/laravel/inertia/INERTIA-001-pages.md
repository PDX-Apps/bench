# Inertia pages (Laravel side)

Controllers return **`Inertia::render('Page/Name', [props])`** instead of JSON or a Blade view. Props are serialized to the page component.

```php
use Inertia\Inertia;

final class OrderController extends Controller
{
    public function index(Request $request): Response
    {
        return Inertia::render('Orders/Index', [
            'orders'      => OrderResource::collection(Order::query()->latest()->paginate(20)),
            // deferred — loaded in a follow-up request after first paint:
            'stats'       => Inertia::defer(fn () => $this->stats()),
        ]);
    }

    public function show(Order $order): Response
    {
        return Inertia::render('Orders/Show', ['order' => new OrderResource($order)]);
    }
}
```

## Shared props (every page) — `HandleInertiaRequests`

```php
final class HandleInertiaRequests extends Middleware
{
    public function share(Request $request): array
    {
        return array_merge(parent::share($request), [
            'auth'  => ['user' => $request->user()],
            'flash' => ['status' => fn () => $request->session()->get('status')],
            // resolved once, remembered client-side across visits:
            'countries' => Inertia::once(fn () => Country::all()),
        ]);
    }
}
```

## Conventions

- **`Inertia::render('Dir/Page', [...])`** — the name maps to the page component (`resources/js/Pages/Dir/Page.{vue,tsx}`).
- **Props are the page's data** — pass API Resources, not raw models; paginate as usual (the paginator serializes with `links`/`meta`).
- **`Inertia::defer(fn)`** for expensive props (loaded after first paint); **`Inertia::lazy`/closures** for props only sent on partial reloads.
- **Shared props** (auth, flash, locale) via `HandleInertiaRequests::share()`; **`Inertia::once`** for static-ish data.
- **Redirects** after mutations (`return to_route('orders.show', $order)`) — Inertia follows them; validation errors come back as `errors` automatically.
- Routes are normal Laravel routes (web middleware) — there is **no API layer** for page data.

## Don't

- Don't return JSON for page data — that's what props are for. Don't pass raw Eloquent models (use Resources). Don't build a separate API for what a page already receives as props.

## See also

- [INERTIA-002-forms](INERTIA-002-forms.md) · core: `<PLUGIN_ROOT>/patterns-built/laravel/http/resources/RESOURCE-001-api-resources.md`
