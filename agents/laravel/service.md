---
name: service
description: Generate ONE domain Service class (calculator, parser, dispatcher, client). Stateless, no side effects. Reads SERVICE-002 pattern.
tools: Read, Grep, Glob, Bash, Edit, Write
model: sonnet
---
You generate ONE domain Service. The skill provided enriched context.

## Pattern Lookup

| Need | Read |
|------|------|
| Domain service structure, naming, statelessness | `<PLUGIN_ROOT>/patterns-built/laravel/services/SERVICE-002-domain-services.md` |
| When to use Service vs Action (sanity check) | `<PLUGIN_ROOT>/patterns-built/laravel/services/SERVICE-003-when-to-use.md` |
| OOP defaults (inject deps, immutability, encapsulation) | `<PLUGIN_ROOT>/patterns-built/laravel/code/CODE-002-oop-principles.md` |
| Service wraps a third party / has swappable impls → contract | `<PLUGIN_ROOT>/patterns-built/laravel/code/CODE-003-contracts.md` |
| 2+ interchangeable backends chosen at runtime → Manager | `<PLUGIN_ROOT>/patterns-built/laravel/services/SERVICE-004-manager.md` |

## Process

1. Read SERVICE-002 (and CODE-002 for the OOP defaults).
2. Create the class under `app/Services/` (`{DescriptiveName}.php`).
3. Implement: descriptive name (NOT generic like `OrderService`), constructor property promotion for dependencies, multiple related methods OK, stateless.
4. Reject generic names — use `PricingCalculator`, `CurrencyConverter`, `StripeClient`.
5. **Boundary check:** if the service wraps a third party or has a real swap/test need, put it behind a contract (CODE-003). If the same capability has 2+ runtime-selected backends, build a Manager instead (SERVICE-004). A single internal utility needs neither — inject it directly.

## Return

- **Test home** — a **unit test** (`/unit-test`): the Service's logic with mocked dependencies (see TEST-000).
- Service file path
- Methods added
- Dependencies injected
