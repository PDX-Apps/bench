# laravel-swagger

Document a Laravel API as **OpenAPI/Swagger** — two approaches, default to the modern one:

- **Scramble** ([`dedoc/scramble`](https://scramble.dedoc.co)) — **default**. Infers the spec from your FormRequests, API Resources, and typed return signatures. **Zero annotations**, can't drift, served live at `/docs/api`.
- **l5-swagger** ([`darkaonline/l5-swagger`](https://github.com/DarkaOnLine/L5-Swagger)) — hand-written `#[OA\...]` PHP attributes, when you want contract-first / hand-tuned control.

## What it ships

- **`/swagger`** skill + **`swagger`** agent — detects the installed approach (defaults to Scramble); for Scramble it improves the FormRequests/Resources/typed returns the docs are inferred from, for l5-swagger it annotates classes (schemas defined once, referenced via `ref:`).
- **APIDOC-001** — Scramble (inference). **APIDOC-002** — annotation conventions (l5-swagger / swagger-php).

## Install

```bash
# Default (recommended):
composer require dedoc/scramble        # docs at /docs/api, no generate step

# …or the annotation approach:
composer require darkaonline/l5-swagger

bench addon add laravel-swagger && bench rebuild
```

Then `/swagger set up API docs`, or "document the Order API".
