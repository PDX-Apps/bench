# DTO-002-self-validating

## Pattern

Self-validating DTOs that automatically validate input before construction using trait + interface pair.

## Dependencies

- `dto/DTO-001-request-data.md` - Basic DTOs as simple data structures

## Why

Reduces boilerplate when creating DTOs from untrusted input (webhooks, CLI, imports). Validation happens automatically in a single call.

## Structure

### Interface

```php
<?php

declare(strict_types=1);

namespace App\Data\Contracts;

interface ValidatesDTO
{
    /**
     * Validation rules for this DTO.
     */
    public static function rules(): array;

    /**
     * Validate an input array using DTO rules.
     *
     * @throws \Illuminate\Validation\ValidationException
     */
    public static function validate(array $input): array;
}
```

### Trait (Default Implementation)

```php
<?php

declare(strict_types=1);

namespace App\Data\Concerns;

use Illuminate\Support\Facades\Validator;

trait ValidatesInput
{
    /**
     * Default validation implementation.
     *
     * @throws \Illuminate\Validation\ValidationException
     */
    public static function validate(array $input): array
    {
        return Validator::make($input, static::rules())->validate();
    }
}
```

**Note:** The trait provides a default `validate()` implementation. DTOs can optionally add `fromInput()` for automatic validation + construction.

## Example: HouseholdData

```php
<?php

declare(strict_types=1);

namespace Modules\Household\Data;

use App\Data\Concerns\ValidatesInput;
use App\Data\Contracts\ValidatesDTO;
use Modules\Household\Rules\ValidHouseholdName;

readonly class HouseholdData implements ValidatesDTO
{
    use ValidatesInput; // Provides validate() implementation

    public function __construct(
        public string $name,
        public int $maxMembers,
    ) {
    }

    public static function rules(): array
    {
        return [
            'name' => ['required', 'string', new ValidHouseholdName, 'max:100'],
            'max_members' => ['required', 'integer', 'min:1', 'max:10'],
        ];
    }

    // Optional: Add fromInput() for convenience
    public static function fromInput(array $input): self
    {
        $validated = self::validate($input);

        return new self(
            name: $validated['name'],
            maxMembers: $validated['max_members'],
        );
    }
}
```

## Usage in Job

```php
<?php

declare(strict_types=1);

namespace Modules\Household\Jobs;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Validation\ValidationException;
use Modules\Household\Actions\CreateHouseholdAction;
use Modules\Household\Data\HouseholdData;

class ProcessHouseholdWebhookJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable;

    public function __construct(
        public array $payload,
    ) {
    }

    public function handle(CreateHouseholdAction $action): void
    {
        try {
            // Automatically validates - single line!
            $data = HouseholdData::fromInput($this->payload);

            $household = $action->execute($data);
        } catch (ValidationException $e) {
            // Handle validation failure
            Log::warning('Invalid webhook payload', [
                'errors' => $e->errors(),
                'payload' => $this->payload,
            ]);

            $this->fail($e);
        }
    }
}
```

## Usage in Command

```php
<?php

namespace Modules\Household\Console;

use Illuminate\Console\Command;
use Modules\Household\Actions\CreateHouseholdAction;
use Modules\Household\Data\HouseholdData;

class ImportHouseholdsCommand extends Command
{
    protected $signature = 'households:import {file}';

    public function handle(CreateHouseholdAction $action): void
    {
        $households = json_decode(file_get_contents($this->argument('file')), true);

        foreach ($households as $householdData) {
            try {
                // Validates each row
                $data = HouseholdData::fromInput($householdData);
                $action->execute($data);

                $this->info("Imported: {$data->name}");
            } catch (ValidationException $e) {
                $this->error("Failed: " . json_encode($e->errors()));
            }
        }
    }
}
```

## Type-Hinted Helper

```php
// Accept any self-validating DTO
class DataImporter
{
    public function import(ValidatesDTO $dataClass, array $records): void
    {
        foreach ($records as $record) {
            $data = $dataClass::fromInput($record);
            // Process...
        }
    }
}

// Usage
$importer->import(HouseholdData::class, $records);
```

## Key Points

- Trait + Interface work together as a pair
- Interface enforces `rules()` and `validate()` methods
- Trait provides default `validate()` implementation
- Throws `ValidationException` on validation failure
- `fromInput()` is optional - add if you need automatic validation + construction
- Works anywhere: jobs, commands, services
- Type safety via `ValidatesDTO` interface

## When NOT to Use

**Don't use fromInput() in:**
- FormRequests (already validated, use `$request->data()`)
- After manual validation (use `fromValidated()` directly)
- When you need custom error handling per field

## Comparison

```php
// Before (manual)
$validated = validator($this->payload, HouseholdData::rules())->validate();
$data = HouseholdData::fromValidated($validated);

// After (automatic)
$data = HouseholdData::fromInput($this->payload);
```

Eliminates 2 lines per usage, ensures consistent validation.
