---
description: Generate a Laravel AI Agent class (laravel/ai SDK) — class structure, instructions, tools wiring, structured output, conversation memory, streaming. Use whenever the user mentions an AI agent, LLM assistant, RAG agent, chatbot, AI sales coach, or any class that wraps an OpenAI/Anthropic/Gemini call with a typed API.
argument-hint: [what the user needs]
---

You're the **/ai-agent** skill. Translate the user's AI agent request into an enriched delegation to the `ai-agent` agent.

The user's request: **$ARGUMENTS**

## Step 1: Parse

Extract:
- **Agent class name** — `{Domain}{Role}` (e.g., `SalesCoach`, `EmailSummarizer`, `RefundsAgent`)
- **Purpose** — what the agent does (1 sentence)
- **Provider/model preference** if mentioned (OpenAI/Anthropic/Gemini; model name)
- **Tools** the agent needs (list, even if rough — these may exist or need generating)
- **Structured output?** Does the agent return parsed data (`HasStructuredOutput`) or free-form text?
- **Conversation memory?** Multi-turn (`RemembersConversations`) or one-shot?
- **Streaming?** UI-facing (yes) vs batch/queued (no)

## Step 2: Inspect

```bash
ls app/Ai/Agents/ 2>/dev/null || echo "AI_DIR_MISSING"
ls app/Ai/Tools/ 2>/dev/null
grep -l "laravel/ai" composer.json composer.lock 2>/dev/null && echo "package installed" || echo "PACKAGE_MISSING"
ls config/ai.php 2>/dev/null && echo "config exists" || echo "config not published"
```

## Step 3: Resolve Ambiguity

- `laravel/ai` not installed → flag: "Install first: `composer require laravel/ai && php artisan vendor:publish --provider=\"Laravel\\Ai\\AiServiceProvider\" && php artisan migrate`"
- Tools referenced that don't exist → flag: "Agent will reference `LookupOrder` tool — doesn't exist. Generate via `/ai-tool` first?"
- Provider unclear → pick a sensible default based on intent (Anthropic for reasoning, OpenAI for cost, Gemini for multi-modal)
- Conversation memory unclear → ask: "One-shot prompt (no memory) or multi-turn conversation (`RemembersConversations` trait)?"

## Step 4: Build Context Blob

```
Context for ai-agent agent:
- Class: {Name}
- Path: app/Ai/Agents/{Name}.php
- Purpose: {one-line description}
- Provider: Lab::Anthropic | Lab::OpenAI | Lab::Gemini
- Model: claude-haiku-4-5 | gpt-4o-mini | etc.
- Configuration: temperature, max-steps, max-tokens (if user specified)
- Contracts: [Agent, HasTools?, HasStructuredOutput?, Conversational?, HasMiddleware?]
- Tools: [list of tool class names with their paths or "to-be-created"]
- Schema (for HasStructuredOutput): {field: type description}
- Conversation memory: yes/no (RemembersConversations trait + DB tables already migrated?)
- Streaming: yes/no
- Constructor deps: (User $user)? other context?
- Existing agents in app/Ai/Agents/: [list]
```

## Step 5: Delegate

Task tool, `subagent_type: "bench:ai-agent"`, pass the blob.

## Step 6: Synthesize

> "Created `app/Ai/Agents/SalesCoach.php` (Anthropic, claude-haiku, temp 0.4). Implements `Agent, HasTools, HasStructuredOutput, Conversational`. Wired tools: `RetrievePreviousTranscripts`, `RandomNumberGenerator`. Structured output: `{feedback, score, next_steps}`. Conversation memory enabled. Invoke: `(new SalesCoach(user: \$user))->prompt('...')`. Suggest `/ai-tool` for any missing tool classes."

## When to Ask vs Assume

- Provider: assume Anthropic for reasoning, OpenAI for cost; only ask if request implies multi-provider
- Streaming: assume queued/batch unless user describes a chat UI
- Memory: ask once — it's a binary architectural decision
- PII compliance: assume YES, follow DATA-001 (hash, redact, never log raw)
