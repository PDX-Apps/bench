# AI-001-agents

## Pattern

Laravel AI Agents are class-based wrappers around an LLM (OpenAI, Anthropic, Gemini, etc.) that bundle instructions, tools, memory, and structured output. They give you a typed, testable API for AI work — not a bag of one-off API calls.

**Install:**
```bash
composer require laravel/ai
php artisan vendor:publish --provider="Laravel\Ai\AiServiceProvider"
php artisan migrate
```

(Ships with Laravel 13; installable on L12 too.)

## Structure

**File location:** `app/Ai/Agents/`

**Scaffold:**
```bash
php artisan make:agent SalesCoach
php artisan make:agent SalesCoach --structured   # with JSON schema output
```

**Basic agent:**
```php
<?php

declare(strict_types=1);

namespace App\Ai\Agents;

use App\Models\User;
use Laravel\Ai\Attributes\Model;
use Laravel\Ai\Attributes\Provider;
use Laravel\Ai\Attributes\Temperature;
use Laravel\Ai\Concerns\RemembersConversations;
use Laravel\Ai\Contracts\Agent;
use Laravel\Ai\Contracts\Conversational;
use Laravel\Ai\Enums\Lab;
use Laravel\Ai\Promptable;
use Stringable;

#[Provider(Lab::Anthropic)]
#[Model('claude-haiku-4-5-20251001')]
#[Temperature(0.4)]
class SalesCoach implements Agent, Conversational
{
    use Promptable;
    use RemembersConversations;

    public function __construct(public User $user) {}

    public function instructions(): Stringable|string
    {
        return 'You are a sales coach. Analyze transcripts and provide specific, actionable feedback. Keep responses under 200 words.';
    }
}
```

**Invoke:**
```php
$response = (new SalesCoach(user: $user))->prompt('Analyze this sales transcript: ...');
return (string) $response;
```

## Configuration Attributes (declarative)

Put generation parameters at the top of the class as attributes — declarative beats per-call args for stable agent behavior:

| Attribute | Purpose |
|-----------|---------|
| `#[Provider(Lab::Anthropic)]` | Which provider (OpenAI, Anthropic, Gemini, etc.) |
| `#[Model('...')]` | Specific model ID |
| `#[Temperature(0.4)]` | Randomness (0.0–2.0) |
| `#[MaxTokens(4096)]` | Max output tokens |
| `#[MaxSteps(10)]` | Max tool-call iterations |
| `#[Timeout(120)]` | Seconds before request abort |
| `#[TopP(0.9)]` | Nucleus sampling |
| `#[UseCheapestModel]` | Cost optimization marker |
| `#[UseSmartestModel]` | Quality optimization marker |

Override at call site when needed:
```php
$response = (new SalesCoach(user: $user))->prompt(
    'Analyze this...',
    provider: Lab::OpenAI,
    model: 'gpt-4o',
    timeout: 180,
);
```

## Structured Output

For agents that should return parsed data (not free-form text), implement `HasStructuredOutput`:

```php
use Illuminate\Contracts\JsonSchema\JsonSchema;
use Laravel\Ai\Contracts\HasStructuredOutput;

class SalesCoach implements Agent, HasStructuredOutput
{
    use Promptable;

    public function schema(JsonSchema $schema): array
    {
        return [
            'feedback' => $schema->string()->required(),
            'score' => $schema->integer()->min(1)->max(10)->required(),
            'next_steps' => $schema->array()->items($schema->string())->required(),
        ];
    }
}

$response = (new SalesCoach)->prompt('Analyze this transcript: ...');
$response['score'];      // typed access
$response['feedback'];
```

## Conversation Memory

Add `RemembersConversations` trait + `Conversational` contract to persist multi-turn conversations:

```php
class SalesCoach implements Agent, Conversational
{
    use Promptable, RemembersConversations;
    // ...
}

// Start new conversation
$response = (new SalesCoach)->forUser($user)->prompt('Hello!');
$conversationId = $response->conversationId;

// Continue existing conversation
$response = (new SalesCoach)
    ->continue($conversationId, as: $user)
    ->prompt('Tell me more about that.');
```

For user-side relationship access:
```php
use Laravel\Ai\Concerns\HasConversations;

class User extends Authenticatable
{
    use HasConversations;
}

$conversations = $user->conversations()->latest()->paginate(20);
```

The package creates `agent_conversations` and `agent_conversation_messages` tables automatically.

## Provider-Specific Options

When a single agent must run across providers, switch options per provider:

```php
use Laravel\Ai\Contracts\HasProviderOptions;
use Laravel\Ai\Enums\Lab;

class SalesCoach implements Agent, HasProviderOptions
{
    use Promptable;

    public function providerOptions(Lab|string $provider): array
    {
        return match ($provider) {
            Lab::OpenAI => [
                'reasoning' => ['effort' => 'low'],
            ],
            Lab::Anthropic => [
                'thinking' => ['budget_tokens' => 1024],
            ],
            default => [],
        };
    }
}
```

## Streaming Responses

For UI-facing agents, stream tokens as they arrive:

```php
use Laravel\Ai\Responses\StreamedAgentResponse;

Route::get('/coach', function () {
    return (new SalesCoach(user: auth()->user()))
        ->stream('Analyze this transcript: ...');
});

// With a callback after streaming completes (e.g., persist final text)
return (new SalesCoach)
    ->stream('...')
    ->then(function (StreamedAgentResponse $response) {
        // $response->text, $response->events, $response->usage
    });

// For Vercel AI SDK consumers:
return (new SalesCoach)
    ->stream('...')
    ->usingVercelDataProtocol();
```

## Queueing

Long-running agents go to the queue:

```php
use Laravel\Ai\Responses\AgentResponse;

(new SalesCoach)
    ->queue('Analyze this transcript: ...')
    ->then(function (AgentResponse $response) {
        // Handle response
    })
    ->catch(function (\Throwable $e) {
        // Handle failure
    });
```

## Agent Middleware

Wrap every prompt/response (e.g., logging, redaction, rate limiting):

**File location:** `app/Ai/Middleware/`

```php
// php artisan make:agent-middleware LogPrompts

namespace App\Ai\Middleware;

use Closure;
use Laravel\Ai\Prompts\AgentPrompt;
use Laravel\Ai\Responses\AgentResponse;

class LogPrompts
{
    public function handle(AgentPrompt $prompt, Closure $next)
    {
        Log::channel('ai')->info('prompt', ['hash' => hash('sha256', $prompt->prompt)]);

        return $next($prompt)->then(function (AgentResponse $response) {
            Log::channel('ai')->info('response', ['tokens' => $response->usage->totalTokens ?? null]);
        });
    }
}
```

Wire it up:
```php
use Laravel\Ai\Contracts\HasMiddleware;

class SalesCoach implements Agent, HasMiddleware
{
    public function middleware(): array
    {
        return [new LogPrompts()];
    }
}
```

## Anonymous Agents

For one-off prompts that don't deserve their own class:

```php
use function Laravel\Ai\agent;
use Illuminate\Contracts\JsonSchema\JsonSchema;

$response = agent(
    instructions: 'You are an expert at software development.',
    tools: [],
)->prompt('Tell me about Laravel');

// With structured output
$response = agent(
    schema: fn (JsonSchema $schema) => [
        'count' => $schema->integer()->required(),
    ],
)->prompt('Count the words in: "Hello world from Laravel"');

return $response['count'];
```

Prefer named classes for anything reused, anything tested, anything with non-trivial instructions. Use anonymous agents for prototypes and truly one-shot calls.

## Compliance

⚠️ Apply the standard PII rules (see `DATA-001-compliance-and-logging`):
- NEVER log raw prompts that may contain PII — log a hash or redacted summary
- NEVER include PII in instructions (they become part of every request)
- Use middleware to redact user input before it hits the provider if uncertain

## Key Points

- Lives in `app/Ai/Agents/`
- Naming: `{Purpose}{Role}` — `SalesCoach`, `EmailSummarizer`, `RefundsAgent`
- Configure provider/model/temp via attributes — declarative, visible
- Use structured output when you want typed data, not free-form text
- Use `RemembersConversations` for multi-turn (creates DB tables for history)
- Stream for UI-facing agents, queue for long-running ones
- Middleware for cross-cutting concerns (logging, redaction)
- See `AI-002-tools` for giving agents capabilities beyond text
- See `AI-003-embeddings` for embeddings + vector search (RAG)

## When to Use

✅ **Use AI Agents for:**
- Domain-specific assistants (sales coach, email summarizer, support triage)
- Multi-turn conversations with persistent memory
- Structured-output extraction (parsing documents to typed data)
- Tool-using agents (RAG, function calling)

❌ **Don't use AI Agents for:**
- Deterministic logic (write code, not prompts)
- Single one-off prompts where an anonymous `agent()` call is enough
- Hard real-time work (LLM latency is unpredictable)
