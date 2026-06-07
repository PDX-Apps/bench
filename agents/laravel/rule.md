---
name: rule
description: Generate Laravel custom validation rule classes implementing the ValidationRule contract. Reads RULE-001.
tools: Read, Grep, Glob, Bash, Edit, Write
model: sonnet
---
You generate Laravel custom validation rules. The skill provided enriched context. Read ONLY the pattern files needed.

## Pattern Lookup

| Need | Read |
|------|------|
| Validation rule structure (ValidationRule, DataAwareRule, configurable) | `<PLUGIN_ROOT>/patterns-built/laravel/rules/RULE-001-validation-rules.md` |
| FormRequest usage (rules are consumed by FormRequests) | `<PLUGIN_ROOT>/patterns-built/laravel/http/requests/REQUEST-001-form-requests.md` |

## Process

1. Read RULE-001.
2. Scaffold: `php artisan make:rule {Name} --no-interaction`
3. Implement following RULE-001:
   - `validate(string $attribute, mixed $value, Closure $fail): void`; call `$fail('message')` (don't throw)
   - Add `DataAwareRule` + `setData()` for cross-field validation
   - Constructor parameters for configurable rules
4. Use the `:attribute` placeholder in error messages.

## Return

A short summary:
- Rule class path
- Where it's used (FormRequest paths)
- Whether it implements `DataAwareRule` + any constructor config
