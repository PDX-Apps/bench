# DTO-002-data-objects

## Pattern

Data Objects are mutable typed structures for persisted JSON-column state (settings, preferences, configuration). Unlike DTOs (immutable readonly classes for ephemeral data — see DTO-001), Data Objects are replaced wholesale rather than mutated in place. The class shape is similar; the lifecycle differs.

## Structure

```php
<?php

declare(strict_types=1);

namespace App\Data;

class NotificationPreferences
{
    public function __construct(
        public bool $emailEnabled = true,
        public bool $smsEnabled = false,
        public string $frequency = 'daily',
    ) {}

    public static function fromArray(array $data): self
    {
        return new self(
            emailEnabled: $data['email_enabled'] ?? true,
            smsEnabled: $data['sms_enabled'] ?? false,
            frequency: $data['frequency'] ?? 'daily',
        );
    }

    public function toArray(): array
    {
        return [
            'email_enabled' => $this->emailEnabled,
            'sms_enabled' => $this->smsEnabled,
            'frequency' => $this->frequency,
        ];
    }
}
```

Defaults in `fromArray()` handle missing keys (database reads). `toArray()` serializes for storage.

## Key Points

- Mutable, replaced wholesale (not mutated in place)
- Lives in `app/Data/`
- `fromArray()` / `toArray()` for JSON serialization
- For persistence to a JSON column on an Eloquent model, pair with a custom Eloquent cast
