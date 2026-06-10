---
description: Set up RAG / semantic search with laravel/ai — a vector column + embeddings ingestion + similarity search (and optional reranking). Use on "/ai-rag", "add semantic search", "set up RAG", "make these documents searchable by meaning", "vector search over X", "embeddings for X".
argument-hint: [the model/content to make searchable + how it's queried]
---

You're the **/ai-rag** skill. Turn the request into an enriched delegation to the `ai-rag` agent (embeddings + vector storage + similarity search). You don't write files.

The user's request: **$ARGUMENTS**

## Step 1: Parse
- The **model/content** to embed (e.g. `Document`, an article body) and where it lives.
- How it's **queried** (a user-facing search? a RAG tool for an agent?) and any **scoping** (per-user, published-only).
- Provider/model + dimensions if specified (else the project's `config/ai.php` default).

## Step 2: Build context blob
```
- Model: {Model}  (content field: {field})
- Vector column: embedding (dimensions: {N or default})
- Ingestion: {on save | queued job for large/batch}
- Query: {whereVectorSimilarTo | SimilaritySearch tool for an agent}
- Scope: {per-user / published / none}
- Rerank: {yes — provider | no}
```

## Step 3: Delegate
Task tool, `subagent_type: "ai-rag"`, pass the blob.

## Step 4: Synthesize
Report the migration (vector column + index), the model cast, the ingestion path, the query/tool, and the **scope** applied (flag if user-owned data isn't scoped). Note `pgvector` is required.

## Not covered by a pattern?

If the request needs a **laravel-ai** capability this addon's patterns don't cover (an advanced or rarely-used feature), delegate to the `doc-lookup` agent (Task tool) with `{ topic, package: "laravel-ai" }`. It reads the package's current docs, returns grounded guidance, and — on your go-ahead — saves it as a project pattern so the next run has it.
