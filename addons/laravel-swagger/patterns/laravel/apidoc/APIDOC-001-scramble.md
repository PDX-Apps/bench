# APIDOC-001 — OpenAPI docs by inference (Scramble)

The **modern default** for documenting a Laravel API: **Scramble** (`dedoc/scramble`) generates an OpenAPI 3.1 spec **from your code** — Form Requests, API Resources, and typed return signatures — with **zero annotations**. The docs can't drift from the code because they *are* the code. Prefer this for any idiomatic Laravel API; reach for annotations only when you need contract-first authoring or hand-tuned control inference can't derive.

## Install

```bash
composer require dedoc/scramble
```

- PHP 8.1+, Laravel 10+. **No annotations, no generate step.** Docs are served live at:
  - `/docs/api` — Swagger-style UI
  - `/docs/api.json` — the OpenAPI 3.1 spec
- Optional config: `php artisan vendor:publish --provider="Dedoc\Scramble\ScrambleServiceProvider" --tag="scramble-config"` → `config/scramble.php` (`api_path`, `info.version`, `info.description`, `servers`).

## How it infers (write normal Laravel, get docs)

The leverage is **idiomatic code** — these *are* the documentation:

- **Request body / params** ← `FormRequest::rules()` (or `$request->validate([...])`). For `GET`/`DELETE` these become query params; otherwise a request body.
  ```php
  class StoreOrderRequest extends FormRequest {
      public function rules(): array {
          return ['reference' => ['required','string','max:255'],
                  'total' => ['required','integer','min:0']];
      }
  }
  ```
- **Responses** ← what the action returns. Return an API Resource and Scramble reads its `toArray()` + the model to shape the schema; `::collection()` and pagination are recognized.
  ```php
  public function index() { return OrderResource::collection(Order::paginate()); }
  public function show(Order $order) { return OrderResource::make($order); }
  ```
- **Path params** ← route-model binding / typed args.

So the way to "document an endpoint" with Scramble is to **generate good FormRequests + API Resources + typed signatures** — bench's own `/request`, `/resource`, `/controller` already produce exactly what Scramble reads.

## Auth (bearer / Sanctum)

Register a global security scheme once in a service provider's `boot()`:

```php
use Dedoc\Scramble\Scramble;
use Dedoc\Scramble\Support\Generator\SecurityScheme;
use Dedoc\Scramble\Support\Generator\OpenApi;

Scramble::afterOpenApiGenerated(function (OpenApi $openApi) {
    $openApi->secure(SecurityScheme::http('bearer'));
});
```

## Config & versioning

- Document a non-`api` prefix or brand the docs: set `scramble.api_path`, `scramble.info.version` / `description` (Markdown), `scramble.servers` in `config/scramble.php`.
- Multiple API versions: `Scramble::registerApi('v2', [...])->expose(ui: '/docs/v2/api', document: '/docs/v2/openapi.json')`.

## PHPDoc nudges (the few things inference can't see)

- `/** @query */` on a field that should be a query param on a non-GET route.
- `@response` PHPDoc for custom error envelopes / non-standard responses inference can't derive (validation `422` is inferred automatically).

## Key Points

- **Zero annotations** — docs inferred from FormRequests + Resources + typed returns; OpenAPI 3.1 at `/docs/api`.
- The real scaffolding leverage is **idiomatic code** (FormRequest + Resource + typed signatures) — generate those and the docs follow.
- Global bearer/Sanctum security via `Scramble::afterOpenApiGenerated(...->secure(...))`.
- Use PHPDoc nudges only for the edge cases (query params on non-GET, custom error shapes).

## When to Use

✅ Any new / convention-following Laravel API — docs stay correct for free.
❌ Contract-first APIs, or specs whose shape inference can't derive — use annotations there.
