# AI-002-tools

## Pattern

Tools give an AI Agent (AI-001) the ability to **do** things — query the database, call an API, search a vector store, hand off to another agent. The model decides when to call a tool; the tool's class executes it.

## Structure

**File location:** `app/Ai/Tools/`

**Scaffold:**
```bash
php artisan make:tool RetrievePreviousTranscripts
```

**Basic tool:**
```php
<?php

declare(strict_types=1);

namespace App\Ai\Tools;

use Illuminate\Contracts\JsonSchema\JsonSchema;
use Laravel\Ai\Contracts\Tool;
use Laravel\Ai\Tools\Request;
use Stringable;

class RandomNumberGenerator implements Tool
{
    public function description(): Stringable|string
    {
        return 'Generate a cryptographically secure random integer in a range.';
    }

    public function handle(Request $request): Stringable|string
    {
        return (string) random_int($request['min'], $request['max']);
    }

    public function schema(JsonSchema $schema): array
    {
        return [
            'min' => $schema->integer()->min(0)->required(),
            'max' => $schema->integer()->required(),
        ];
    }
}
```

**Attach to agent (see AI-001):**
```php
class SalesCoach implements Agent, HasTools
{
    public function tools(): iterable
    {
        return [
            new RandomNumberGenerator(),
            new RetrievePreviousTranscripts($this->user),
        ];
    }
}
```

The model sees the tool's `description()` and `schema()` and decides if/when to call it. The framework handles the round-trip.

## Tool Design Rules

- **Description should be plain English, action-oriented.** "Generate a random integer in a range" — not "RNG service."
- **Schema is the contract.** Every input the tool needs goes in the schema with types + required markers.
- **`handle()` returns a string** (or `Stringable`) — the LLM sees that as the tool's output. Format data as compact text or JSON.
- **Inject runtime context via constructor** (e.g., the current user) — don't accept it through the schema (don't trust the LLM with auth context).
- **Validate `$request` parameters defensively** — the LLM may pass garbage. Treat tool inputs like API input.
- **Failures should return a useful error string** the LLM can recover from, not throw — e.g., `"No transcripts found for this user"` rather than letting an exception bubble up.

## Built-in Tools

### Similarity Search (RAG)

The most common tool — searches a vector-indexed model and returns relevant rows:

```php
use App\Models\Document;
use Laravel\Ai\Tools\SimilaritySearch;

public function tools(): iterable
{
    return [
        // Simplest form
        SimilaritySearch::usingModel(Document::class, 'embedding'),

        // With threshold + limit + scoping
        SimilaritySearch::usingModel(
            model: Document::class,
            column: 'embedding',
            minSimilarity: 0.7,
            limit: 10,
            query: fn ($query) => $query->where('user_id', $this->user->id)->where('published', true),
        ),

        // Custom closure for complex queries
        new SimilaritySearch(using: function (string $query) {
            return Document::query()
                ->where('user_id', $this->user->id)
                ->whereVectorSimilarTo('embedding', $query)
                ->limit(10)
                ->get();
        }),
    ];
}
```

See `AI-003-embeddings` for the embedding generation + vector schema setup.

### Provider Tools (native AI provider features)

Some providers ship server-side tools (web search, file search). Use them via `Laravel\Ai\Providers\Tools`:

```php
use Laravel\Ai\Providers\Tools\WebSearch;
use Laravel\Ai\Providers\Tools\WebFetch;
use Laravel\Ai\Providers\Tools\FileSearch;

public function tools(): iterable
{
    return [
        (new WebSearch())->max(5)->allow(['laravel.com', 'php.net']),
        (new WebFetch())->max(3)->allow(['docs.laravel.com']),
        new FileSearch(stores: ['store_id_from_provider']),
    ];
}
```

Provider tools run on the AI provider's infrastructure, not yours — they're paid per call.

## Sub-Agents as Tools

For complex workflows, hand off to a specialist agent as if it were a tool. Implement `CanActAsTool` on the sub-agent:

```php
use Laravel\Ai\Contracts\CanActAsTool;

class RefundsAgent implements Agent, CanActAsTool
{
    use Promptable;

    public function instructions(): string
    {
        return 'You are a refunds specialist. Given an order ID and reason, determine eligibility and process the refund if appropriate.';
    }

    public function name(): string
    {
        return 'refunds_specialist';
    }

    public function description(): string
    {
        return 'Determine whether an order is eligible for a refund and process it.';
    }

    public function tools(): iterable
    {
        return [new LookupOrder()];
    }
}

// Use it as a tool on the parent agent
class CustomerSupportAgent implements Agent, HasTools
{
    public function tools(): iterable
    {
        return [
            new RefundsAgent(),       // The router agent will call this when refund is the right path
            new PaymentsAgent(),
            new OrderStatusAgent(),
        ];
    }
}
```

This is the "agent of agents" pattern — keep each agent focused, compose them.

## Naming

| Tool type | Convention | Example |
|-----------|------------|---------|
| Action | `{Verb}{Object}` | `LookupOrder`, `SendInviteEmail`, `RefundOrder` |
| Retrieval | `Retrieve{Object}` or `Find{Object}` | `RetrievePreviousTranscripts`, `FindSimilarDocuments` |
| Computation | `{Object}Calculator` or `Compute{Object}` | `TaxCalculator`, `ComputeShipping` |
| Sub-agent | `{Domain}Agent` | `RefundsAgent`, `PaymentsAgent` |

## Limiting Tool Iteration

Models can loop on tool calls. Cap with `MaxSteps`:

```php
#[\Laravel\Ai\Attributes\MaxSteps(10)]
class SalesCoach implements Agent, HasTools { /* ... */ }
```

Default behavior is generous; set lower for cost-sensitive agents.

## Testing Tools

Tools are plain classes — test them directly without invoking the AI:

```php
public function test_random_number_generator_returns_int_in_range(): void
{
    $tool = new RandomNumberGenerator();
    $request = new Request(['min' => 1, 'max' => 100]);

    $output = $tool->handle($request);

    $this->assertIsString($output);
    $this->assertGreaterThanOrEqual(1, (int) $output);
    $this->assertLessThanOrEqual(100, (int) $output);
}
```

For testing agent-tool interaction (did the agent call the right tool with the right args?), use the AI testing helpers (see Laravel docs — `Laravel\Ai\Testing`).

## Compliance

- ⚠️ **Tool outputs become part of the model's context.** If a tool returns PII, that PII may end up in the response. Filter at the tool level.
- ⚠️ **Tools execute with your app's permissions.** Don't expose database-write tools to user-facing agents without strict scoping (per-user `WHERE` clauses, validation).
- ⚠️ **Authentication: inject the current user via constructor.** Never trust an `user_id` schema parameter — the model can pass any value.

## Key Points

- Lives in `app/Ai/Tools/`
- Implements `Laravel\Ai\Contracts\Tool` — three methods: `description()`, `handle()`, `schema()`
- Description and schema are the contract with the LLM
- Inject runtime context (user, request) via constructor
- Validate parameters defensively
- Return strings — the LLM consumes them as text
- Use `SimilaritySearch` for RAG (see AI-003)
- Use `CanActAsTool` to compose agents
- Cap tool-call loops with `#[MaxSteps]` on the parent agent
- Tools are testable as plain PHP classes

## When to Use

✅ **Tools for:**
- Database lookups the LLM needs to answer accurately
- Calling internal APIs (`Refund`, `SendInvite`)
- RAG (search vector store)
- Composing specialist agents (`CanActAsTool`)

❌ **Not tools for:**
- Pure prompt instructions (put those in `instructions()`)
- Static configuration (use config files, not tools)
- Anything the model can do reliably without a tool call (don't add a `WordCounter` tool for a model that can count words)
