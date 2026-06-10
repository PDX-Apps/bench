# AI-005-testing

## Pattern

Never hit a real provider in tests — it's slow, costs money, and is non-deterministic. `laravel/ai` lets you **fake an agent** with canned responses and assert what it was prompted with. The fake is **static, on the agent class itself** (not a facade), and takes a **queue of responses**.

## Faking an agent

```php
use App\Ai\Agents\SalesCoach;

// Queue of responses (consumed in order, one per prompt):
SalesCoach::fake(['Great pacing — ask more discovery questions.']);

$response = (new SalesCoach)->prompt('Analyze this transcript: ...');

// Assertions — the argument is a prompt substring (or a closure):
SalesCoach::assertPrompted('Analyze this transcript');
SalesCoach::assertNotPrompted('refund');
SalesCoach::assertNeverPrompted();

// Fail the test if any un-faked real call slips through:
SalesCoach::fake()->preventStrayPrompts();
```

For a **structured-output** agent (`HasStructuredOutput`), the faked response is the array the schema would produce:

```php
SalesCoach::fake([
    ['score' => 8, 'feedback' => 'Strong close.'],
]);

$response = (new SalesCoach)->prompt('Analyze: ...');
$response['score']; // 8
```

## Testing tools directly

A `Tool` is a plain class — test `handle()` with no AI at all:

```php
use Laravel\Ai\Tools\Request;

$tool = new RandomNumberGenerator;
$output = $tool->handle(new Request(['min' => 1, 'max' => 10]));

expect((int) $output)->toBeGreaterThanOrEqual(1)->toBeLessThanOrEqual(10);
```

The other entry points (`Embeddings`, `Image`, `Audio`, `Transcription`) expose `::fake()` in the same spirit — fake them so tests never call a provider.

## Key Points

- **`AgentClass::fake([...responses])`** — static, on the agent class; responses are a queue (strings, or arrays for structured output).
- **`AgentClass::assertPrompted('substring'|closure)`**, `assertNotPrompted(...)`, `assertNeverPrompted()`.
- **`AgentClass::fake()->preventStrayPrompts()`** to catch un-faked real calls.
- **Tools are tested as plain PHP** — call `handle(new Request([...]))` directly.

## When to Use

✅ Every test touching an agent/tool — fake the provider, assert your code's behavior.
❌ Don't assert exact LLM wording in a non-faked call — it's non-deterministic.
