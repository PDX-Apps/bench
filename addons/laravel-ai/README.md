# laravel-ai

Build AI features with the official [`laravel/ai`](https://github.com/laravel/ai) SDK — typed, testable Agents instead of one-off API calls.

## What it ships

- **`/ai-agent`** skill + agent — Agent classes (instructions, provider/model attributes, structured output, conversation memory, streaming, queueing, middleware).
- **`/ai-tool`** skill + agent — Tool classes for function calling (typed schema + `handle()`).
- **AI-001 / AI-002 / AI-003** patterns — agents, tools, and embeddings + vector similarity search (RAG).

## Install

```bash
composer require laravel/ai
php artisan vendor:publish --provider="Laravel\Ai\AiServiceProvider" && php artisan migrate
bench addon add /path/to/bench/addons/laravel-ai
bench rebuild
```

Then `/ai-agent an email summarizer that returns a typed subject + bullet summary`.
