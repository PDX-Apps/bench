# DATA-007-structured-settings

## Pattern

Data Objects for structured JSON columns (settings, preferences, configuration). Unlike DTOs, these are mutable and replaced wholesale.

## DTO vs Data Object

| Type | Class Style | Mutability | Use Case | FormRequest Method |
|------|-------------|------------|----------|-------------------|
| **DTO** | `readonly class` | Immutable | Request data, commands, events | `toDto()` |
| **Data Object** | Regular `class` | Replaced wholesale | Settings, preferences, config | `toData()` |

Both live in `Modules/{Module}/Data/`.

## Structure

```php
<?php

declare(strict_types=1);

namespace Modules\{Module}\Data;

class NotificationPreferences
{
    public function __construct(
        public bool $emailEnabled = true,
        public bool $smsEnabled = false,
        public string $frequency = 'daily',
    ) {}

    /**
     * Validation rules for this Data Object.
     * FormRequests should call this: NotificationPreferences::rules()
     */
    public static function rules(): array
    {
        return [
            'email_enabled' => ['sometimes', 'boolean'],
            'sms_enabled' => ['sometimes', 'boolean'],
            'frequency' => ['sometimes', 'string', 'in:daily,weekly,monthly'],
        ];
    }

    public static function fromArray(array $data): self
    {
        return new self(
            emailEnabled: $data['email_enabled'] ?? true,
            smsEnabled: $data['sms_enabled'] ?? false,
            frequency: $data['frequency'] ?? 'daily',
        );
    }

    /**
     * Merge partial data into current settings.
     */
    public function merge(array $data): self
    {
        return new self(
            emailEnabled: $data['email_enabled'] ?? $this->emailEnabled,
            smsEnabled: $data['sms_enabled'] ?? $this->smsEnabled,
            frequency: $data['frequency'] ?? $this->frequency,
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

## Custom Eloquent Cast

```php
<?php

declare(strict_types=1);

namespace Modules\{Module}\Casts;

use Illuminate\Contracts\Database\Eloquent\CastsAttributes;
use Illuminate\Database\Eloquent\Model;
use Modules\{Module}\Data\NotificationPreferences;

/**
 * @implements CastsAttributes<NotificationPreferences, NotificationPreferences>
 */
class NotificationPreferencesCast implements CastsAttributes
{
    /**
     * @param Model $model
     * @param string $key
     * @param string|null $value
     * @param array<string, mixed> $attributes
     */
    public function get(Model $model, string $key, mixed $value, array $attributes): NotificationPreferences
    {
        $data = $value ? json_decode($value, true) : [];

        return NotificationPreferences::fromArray($data);
    }

    /**
     * @param Model $model
     * @param string $key
     * @param NotificationPreferences $value
     * @param array<string, mixed> $attributes
     */
    public function set(Model $model, string $key, mixed $value, array $attributes): string
    {
        return json_encode($value->toArray());
    }
}
```

## Model Usage

```php
class User extends Model
{
    protected function casts(): array
    {
        return [
            'preferences' => NotificationPreferencesCast::class,
        ];
    }
}

// Reading - always returns typed object with defaults
$user->preferences->emailEnabled; // true (default)
$user->preferences->frequency;    // 'daily' (default)

// Writing - replace the entire object
$user->preferences = new NotificationPreferences(
    emailEnabled: false,
    smsEnabled: true,
    frequency: 'weekly',
);
$user->save();
```

## FormRequest with toData()

**Validation rules live in the Data Object class.** FormRequest delegates to it:

```php
class UpdatePreferencesRequest extends FormRequest
{
    public function rules(): array
    {
        // Delegate to Data Object - single source of truth
        return NotificationPreferences::rules();
    }

    public function toData(NotificationPreferences $current): NotificationPreferences
    {
        // Delegate to merge() for partial updates
        return $current->merge($this->validated());
    }
}
```

Controller:
```php
public function update(UpdatePreferencesRequest $request, User $user)
{
    $user->preferences = $request->toData($user->preferences);
    $user->save();

    return response()->json(['message' => 'Preferences updated']);
}
```

## With Enums

```php
enum NotificationFrequency: string
{
    case Daily = 'daily';
    case Weekly = 'weekly';
    case Monthly = 'monthly';
}

class NotificationPreferences
{
    public function __construct(
        public bool $emailEnabled = true,
        public NotificationFrequency $frequency = NotificationFrequency::Daily,
    ) {}

    public static function fromArray(array $data): self
    {
        return new self(
            emailEnabled: $data['email_enabled'] ?? true,
            frequency: NotificationFrequency::tryFrom($data['frequency'] ?? '')
                ?? NotificationFrequency::Daily,
        );
    }

    public function toArray(): array
    {
        return [
            'email_enabled' => $this->emailEnabled,
            'frequency' => $this->frequency->value,
        ];
    }
}
```

## Key Points

- NOT `readonly` - mutable, but replaced wholesale (not mutated in place)
- Lives in `Modules/{Module}/Data/` alongside DTOs
- **Validation rules live in Data Object** via `static rules()` method
- FormRequest delegates: `return DataClass::rules()`
- Requires custom Eloquent cast for serialization
- `fromArray()` handles defaults for missing keys (for database reads)
- `merge()` handles partial updates (preserves unset fields)
- `toArray()` serializes for database storage
- FormRequest uses `toData()` (not `toDto()`) which delegates to `merge()`
