---
description: Build AI features with the laravel/ai SDK — routes to the right worker for agents, tools (function calling), and RAG (embeddings + vector search). Use on "/ai", "build an AI feature", "add an assistant", "give the agent a tool", "set up RAG / semantic search", or any laravel/ai work when you're not sure which sub-command fits.
argument-hint: [what you want to build with AI]
---

You're the **/ai** delegator for the `laravel/ai` SDK. Read the request, pick the sub-domain(s), and delegate to the matching worker agent(s). You don't write files — the workers do.

The user's request: **$ARGUMENTS**

## Route by domain

| The request is about… | Delegate to | (or call the focused skill) |
|---|---|---|
| An **agent** class — an assistant/coach/summarizer, structured extraction, multi-turn memory, streaming, queueing | `ai-agent` | `/ai-agent` |
| A **tool** — function calling, a DB/API capability the model can invoke, a sub-agent-as-tool | `ai-tool` | `/ai-tool` |
| **RAG / embeddings / semantic search** — vector column + similarity search, ingestion, reranking | `ai-rag` | `/ai-rag` |

A full feature spans domains — e.g. "a support assistant that searches our docs" = an **agent** (`ai-agent`) + a **RAG** tool (`ai-rag`). Sequence the workers (RAG setup first so the agent can wire the `SimilaritySearch` tool), sharing context between them, and report the whole feature.

## Steps
1. **Classify** the request into one or more domains above. If genuinely ambiguous, ask one focused question.
2. **Delegate** to each worker via Task (`subagent_type` = `ai-agent` / `ai-tool` / `ai-rag`), passing the relevant slice of the request. For multi-domain features, order by dependency and pass forward what each produced.
3. **Synthesize** — the classes/migrations created, how to invoke, and any follow-ups (e.g. a model policy, the embeddings migration, queue setup). Flag the PII/compliance notes the workers surface.

> Setup prerequisite: `laravel/ai` must be installed (`composer require laravel/ai`, `vendor:publish`, `migrate`). If it isn't, say so before scaffolding.

## Not covered by a pattern?

If the request needs a **laravel-ai** capability this addon's patterns don't cover (an advanced or rarely-used feature), delegate to the `doc-lookup` agent (Task tool) with `{ topic, package: "laravel-ai" }`. It reads the package's current docs, returns grounded guidance, and — on your go-ahead — saves it as a project pattern so the next run has it.
