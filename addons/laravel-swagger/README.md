# laravel-swagger

Generate OpenAPI/Swagger API docs from PHP attributes (`#[OA\...]`) using [darkaonline/l5-swagger](https://github.com/DarkaOnLine/L5-Swagger).

## What it ships

- **`/swagger`** skill + **`swagger`** agent — annotate models, form requests, API resources, and controllers; regenerate the spec.
- **CODE-002** pattern — the attribute conventions: each class defines its own `#[OA\Schema]`; controllers reference schemas via `ref:` (never inline duplicates); document every API-exposed property with `example`/`format`.

## Install

```bash
composer require darkaonline/l5-swagger
bench addon add /path/to/bench/addons/laravel-swagger
bench rebuild
```

Then `/swagger` to document classes, or ask Claude to "add OpenAPI annotations to the Order API".
