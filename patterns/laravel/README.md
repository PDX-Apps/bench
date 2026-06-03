# Laravel Patterns

Framework patterns for the Laravel side of the plugin.

## Layout

```
laravel/
├── base/                       # Canonical pattern set (current Laravel + PHP)
│   ├── _meta.yaml              # Declares which versions this base targets
│   ├── http/  models/  services/  database/
│   ├── events/  listeners/  testing/  auth/
│   ├── policies/  code/  data/  dto/
│   ├── traits/  modules/  audit/  jobs/
│   ├── rules/  exceptions/  console/
│   └── modules/stubs/
└── overrides/
    ├── laravel-{N}/            # Files that change ONLY for Laravel N
    ├── php-{N}/                # Files that change ONLY for PHP N
    └── laravel-{N}+php-{M}/    # Files where BOTH axes collide
```

## Resolution

The build script resolves each file via this precedence (most specific wins):

1. `overrides/laravel-{L}+php-{P}/{file}` — explicit combined override
2. `overrides/laravel-{L}/{file}` — Laravel-only override
3. `overrides/php-{P}/{file}` — PHP-only override
4. `base/{file}` — fallback

Build output lands in `patterns-built/laravel/`. Agents read from there.

## Override File Format

Every override file declares the base it forked from + a hash for staleness detection:

```markdown
---
overrides: base/models/MODEL-001-structure.md
target: laravel-13+php-8.5
reason: L13's removed observer methods + PHP 8.5 property hooks
base-hash: a3f9c2
---

# MODEL-001-structure (L13 + PHP 8.5)

[full replacement content]
```

`scripts/validate-overrides.sh` checks each override's `base-hash` against the current base file. Mismatches mean the base changed since the override was forked — manual review needed.

## Adding a new override

1. Run `./scripts/diff-from-base.sh <override-target> <pattern-path>` (when written) — copies base file into the override directory and adds the frontmatter automatically
2. Edit the override file with the version-specific changes
3. Commit
4. Run `./scripts/validate-overrides.sh` to confirm it's not flagged
