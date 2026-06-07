# ENUM-001-structure

## Pattern

Well-designed backed enums for status / type / mode fields. The enum is a domain object: it owns the valid set of values **and** the behavior that goes with them (display, classification, allowed transitions) — so callers ask the enum questions instead of scattering `match`/`if` checks across the codebase.

## When an enum fits

- ✅ A fixed, stable set of values (order statuses, notification channels, roles)
- ✅ Values with behavior attached (a status that knows whether it's terminal, a channel that knows its transport)
- ✅ Small-to-medium sets defined in code
- ❌ Values managed at runtime through the UI (e.g. user-defined roles) — those are data rows
- ❌ Large or frequently-changing sets (country codes, currencies) — keep as data tables

## Structure

Back the enum with the type stored in the database (`string` is the usual choice; `int` when the column is numeric). Give every case a one-line docblock describing what it means in the domain.

```php
<?php

declare(strict_types=1);

namespace App\Enums;

enum OrderStatus: string
{
    /** Being assembled — items can still be added or removed. */
    case Draft = 'draft';

    /** Submitted by the customer, awaiting fulfilment. */
    case Placed = 'placed';

    /** Handed to the carrier. */
    case Shipped = 'shipped';

    /** Delivered and closed. No further transitions. */
    case Completed = 'completed';

    /** Cancelled before completion. No further transitions. */
    case Cancelled = 'cancelled';
}
```

## Display methods

Keep presentation on the enum so the UI never re-derives it. A `label()` is almost always worth having; add `color()`/`icon()` when the value drives a badge or status chip.

```php
/** Human-readable label for UI display. */
public function label(): string
{
    return match ($this) {
        self::Draft     => 'Draft',
        self::Placed    => 'Placed',
        self::Shipped   => 'Shipped',
        self::Completed => 'Completed',
        self::Cancelled => 'Cancelled',
    };
}

/** Tailwind/badge colour for status chips. */
public function color(): string
{
    return match ($this) {
        self::Draft                 => 'gray',
        self::Placed, self::Shipped => 'blue',
        self::Completed             => 'green',
        self::Cancelled             => 'red',
    };
}
```

## Domain behavior

Put the rules that depend on the value *on the enum*. Callers ask a question (`$order->status->isEditable()`) instead of comparing against cases.

```php
/** Whether the order can still be edited. */
public function isEditable(): bool
{
    return $this === self::Draft;
}

/** Whether this is a terminal state — no transitions out. */
public function isTerminal(): bool
{
    return in_array($this, [self::Completed, self::Cancelled], true);
}
```

## State transitions

When the enum models a state machine, let it own the allowed moves. One source of truth for "what can follow what".

```php
/** States reachable directly from this one. */
public function allowedTransitions(): array
{
    return match ($this) {
        self::Draft     => [self::Placed, self::Cancelled],
        self::Placed    => [self::Shipped, self::Cancelled],
        self::Shipped   => [self::Completed],
        self::Completed,
        self::Cancelled => [],
    };
}

public function canTransitionTo(self $next): bool
{
    return in_array($next, $this->allowedTransitions(), true);
}
```

## Classifying / filtering cases

Expose named subsets instead of having callers hand-build arrays of cases.

```php
/** Cases a customer can still act on. */
public static function open(): array
{
    return array_filter(self::cases(), fn (self $s) => ! $s->isTerminal());
}
```

## Building from raw values

```php
$status = OrderStatus::from('placed');      // throws ValueError if unknown
$maybe  = OrderStatus::tryFrom($input);     // null if unknown — use for user input
$all    = OrderStatus::cases();             // every case, in declaration order
```

## Naming

- Class: singular noun (`OrderStatus`, `UserRole`, `NotificationChannel`)
- Cases: PascalCase (`Draft`, `Placed`, `SuperAdmin`)
- Values: snake_case matching the DB column (`draft`, `placed`, `super_admin`)
- One-line docblock per case explaining its domain meaning

## Anti-Patterns

- ❌ String constants on the model (`const STATUS_PENDING = 'pending'`) — no type safety, easy to mistype, values scatter
- ❌ Getter methods returning strings (`getStatus(): string`) — recomputed every read, no exhaustiveness checking
- ❌ Behavior living outside the enum (`if ($order->status === 'draft')` sprinkled across controllers) — put the question on the enum (`isEditable()`) so there's one place to change it
- ❌ Non-exhaustive `match` without a default when you intend to cover every case — let `match` throw on an unhandled case rather than hiding it behind `default`
