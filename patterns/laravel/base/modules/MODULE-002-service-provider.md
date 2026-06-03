# MODULE-002-service-provider

## Pattern

Type-safe module ServiceProvider that passes all code quality checks.

## Why Replace Default

The default nwidart/laravel-modules ServiceProvider fails type checking because:
- Missing PHPDoc type annotations
- Dynamic array operations without type hints
- Psalm/PHPStan level 9 strict type errors

## Usage

When creating a new module, replace the generated ServiceProvider with the stub template:

**Template:** `stubs/ModuleServiceProvider.stub`

**Replace:**
1. `{Module}` with PascalCase module name (e.g., `Household`)
2. `{module}` with lowercase module name (e.g., `household`)

## Key Differences from Default

**Type Annotations Added:**
```php
/** @var string $configGeneratorPath */
$configGeneratorPath = config('modules.paths.generator.config.path', 'config');

/** @var array<string, mixed> $existing */
$existing = config($key, []);

/** @var array<int, string> $viewPaths */
$viewPaths = config('view.paths', []);
```

**Type Guards Added:**
```php
if (!$file instanceof SplFileInfo) {
    continue;
}
```

**Visibility Changed:**
```php
// Changed from protected to private (allows Psalm optimization)
private function getPublishableViewPaths(): array
```