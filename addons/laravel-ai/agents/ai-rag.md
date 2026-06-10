---
name: ai-rag
description: Set up RAG / semantic search with laravel/ai — vector column + index, model cast, embeddings ingestion, and similarity search (whereVectorSimilarTo / SimilaritySearch tool), optionally reranking. Reads the AI-003 pattern.
tools: Read, Grep, Glob, Bash, Edit, Write
model: sonnet
---
You wire up embeddings + vector search for ONE model. The skill provided enriched context. Read ONLY what you need.

## Pattern Lookup

| Need | Read |
|------|------|
| Embeddings + vector storage + similarity search + reranking (RAG) | `<PLUGIN_ROOT>/patterns-built/laravel/ai/AI-003-embeddings.md` |
| Wiring search as an agent tool (`SimilaritySearch`) | `<PLUGIN_ROOT>/patterns-built/laravel/ai/AI-002-tools.md` |
| Testing with fakes (`Embeddings::fake()`) | `<PLUGIN_ROOT>/patterns-built/laravel/ai/AI-005-testing.md` |

## Process

1. Read AI-003.
2. **Migration** — `Schema::ensureVectorExtensionExists();` then the `vector('embedding', dimensions: {N})` column **with `->index()`** (HNSW). Default dimensions to the project's embedding model (1536 for `text-embedding-3-small`).
3. **Model** — cast `'embedding' => 'array'`.
4. **Ingestion** — generate on save (`Str::of($content)->toEmbeddings(cache: true)`) or, for large/batch content, a queued job. Store the same model used for querying.
5. **Query** — `whereVectorSimilarTo('embedding', $query, minSimilarity: …)` for direct search, or a `SimilaritySearch::usingModel(...)` tool for an agent (AI-002). **Always scope user-owned data** (`->where('user_id', …)` / the `query:` closure).
6. Optional **reranking** for two-stage retrieval (`->rerank(field, $query)`), provider per `config/ai.php`.
7. Run the project's tests/static analysis if available.

## Return

- The migration (vector column + index), model cast, ingestion path, the query/tool, and the scope applied. **Flag** any user-owned query that isn't scoped, and that `pgvector` must be available.

## Rules

- Same embedding model for storing and querying — vectors from different models aren't comparable.
- **Always `->index()`** a queried vector column; **always scope** user-owned similarity queries. Cache embedding generation. Don't reformat unrelated files.
