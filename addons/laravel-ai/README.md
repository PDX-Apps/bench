# laravel-ai

Build AI features with the official [`laravel/ai`](https://github.com/laravel/ai) SDK (v0.x, built on Prism) — typed, testable Agents, Tools, and RAG instead of one-off API calls.

## What it ships

- **`/ai`** — delegator skill: routes a request to the right worker (agent / tool / RAG), or sequences them for a full feature.
- **`/ai-agent`** skill + `ai-agent` agent — Agent classes (instructions, provider/model attributes, structured output, conversation memory, streaming, queueing, middleware, attachments).
- **`/ai-tool`** skill + `ai-tool` agent — Tool classes for function calling (typed schema + `handle()`; provider tools, MCP, sub-agents-as-tools).
- **`/ai-rag`** skill + `ai-rag` agent — embeddings + vector column/index + similarity search (`whereVectorSimilarTo` / `SimilaritySearch`) + reranking.
- **Patterns** — `AI-001` agents · `AI-002` tools · `AI-003` embeddings/RAG · `AI-004` multi-modal (image/audio/transcription/attachments) · `AI-005` testing (fakes).

## Domains
| You want… | Use |
|---|---|
| An assistant / coach / summarizer / structured extraction | `/ai-agent` |
| A function the model can call (DB/API capability) | `/ai-tool` |
| Semantic search / RAG over your data | `/ai-rag` |
| Not sure / a full feature spanning these | `/ai` |

## Install

```bash
composer require laravel/ai
php artisan vendor:publish --provider="Laravel\Ai\AiServiceProvider" && php artisan migrate
bench addon add laravel-ai && bench rebuild
```

Then `/ai-agent an email summarizer that returns a typed subject + bullet summary`, or `/ai a support assistant that answers from our docs` (agent + RAG).

## Requires
- `laravel/ai` (PHP 8.3+, Laravel 12/13). A provider key (`OPENAI_API_KEY` / `ANTHROPIC_API_KEY` / …) in `.env`.
- For RAG: **pgvector** (PostgreSQL).
