---
description: Generate a Laravel AI Tool class — the laravel/ai SDK Tool that an Agent can call (DB lookup, API call, similarity search, sub-agent handoff). Use whenever the user mentions an AI tool, agent capability, function calling, RAG search, or wants an agent to be able to "do" something concrete beyond text.
argument-hint: [what the user needs]
---

You're the **/ai-tool** skill. Translate the user's AI tool request into an enriched delegation to the `ai-tool` agent.

The user's request: **$ARGUMENTS**

## Step 1: Parse

Extract:
- **Tool class name** — `{Verb}{Object}` (`LookupOrder`, `RetrieveTranscripts`, `RefundOrder`)
- **What it does** — one-sentence description (becomes the LLM-facing `description()`)
- **Input schema** — what params does the LLM pass (name, type, required?)
- **Type**:
  - Custom tool (your own class implementing `Tool`)
  - Similarity search (RAG over an existing model — use `SimilaritySearch::usingModel()`)
  - Sub-agent (another Agent acting as a tool via `CanActAsTool`)
- **Runtime context** — what does the constructor need (the current user? a tenant? config)?
- **Which agent(s) will use it** — for the wiring suggestion

## Step 2: Inspect

```bash
ls app/Ai/Tools/ 2>/dev/null || echo "AI_TOOLS_DIR_MISSING"
ls app/Ai/Agents/ 2>/dev/null   # agents that may need this tool
grep -l "laravel/ai" composer.json composer.lock 2>/dev/null && echo "package installed" || echo "PACKAGE_MISSING"
```

For similarity-search tools, also check:
```bash
ls Modules/{Module}/database/migrations/ | grep -i "embedding\|vector"  # has the vector column migration?
```

## Step 3: Resolve Ambiguity

- `laravel/ai` not installed → flag and stop (suggest `/ai-agent` for install instructions)
- Type unclear (custom vs SimilaritySearch vs sub-agent) → ask one question
- For similarity search, the target model must have a `vector` column with embeddings populated → flag if missing
- For runtime context (user, tenant), inject via constructor — never accept via the schema (LLM can pass arbitrary values)

## Step 4: Build Context Blob

```
Context for ai-tool agent:
- Class: {Name}
- Path: app/Ai/Tools/{Name}.php
- Type: custom | similarity-search | sub-agent-wrapper
- Description (LLM-facing, plain English action verb): "..."
- Schema (LLM-passed inputs): [{name, type, required?}, ...]
- Constructor deps (runtime context, never schema): [User $user, ...]
- handle() returns: string formatted as {plain text | JSON | etc.}
- For similarity-search: target model + column + minSimilarity + limit + scope query
- For sub-agent: wraps {AgentName}, exposed via CanActAsTool
- Used by: [list of agent class paths]
- Existing tools in app/Ai/Tools/: [list]
```

## Step 5: Delegate

Task tool, `subagent_type: "bench:ai-tool"`, pass the blob.

## Step 6: Synthesize

> "Created `app/Ai/Tools/LookupOrder.php`. Schema: `{order_id: required string}`. Injects `User` via constructor (scopes lookup to authorized orders). Returns JSON-formatted order summary. Wired into `RefundsAgent->tools()`."

## When to Ask vs Assume

- Inject runtime context via constructor, NEVER schema → never ask, always enforce
- Validate inputs defensively → never ask, always enforce
- Format output as concise string the LLM can parse → assume; complex objects → JSON

## Anti-Patterns

- ❌ Auth context (`user_id`) in the schema — the LLM can pass anyone's ID. Inject via constructor.
- ❌ Throwing exceptions for "no results" — return a useful string the LLM can react to.
- ❌ Returning huge unfiltered datasets — limit, filter, paginate. The model's context is finite.
- ❌ Side-effecting tools without idempotency — the LLM may retry. Make `handle()` safe to call twice.
