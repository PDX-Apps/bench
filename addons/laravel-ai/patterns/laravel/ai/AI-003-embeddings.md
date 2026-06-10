# AI-003-embeddings

## Pattern

Embeddings turn text into vectors. Stored in a vector column, you can find semantically-similar rows ("what documents talk about X?"). This is the foundation of RAG, semantic search, and recommendation features.

Laravel ships first-party support for generating embeddings, storing them in PostgreSQL via `pgvector`, and querying with `whereVectorSimilarTo()`.

## Generating Embeddings

### One-Shot via Stringable

```php
use Illuminate\Support\Str;

$embedding = Str::of('Napa Valley has great wine.')->toEmbeddings();
// → array of floats: [0.123, 0.456, ...]
```

### Batched (Preferred for Multiple Inputs)

```php
use Laravel\Ai\Embeddings;
use Laravel\Ai\Enums\Lab;

$response = Embeddings::for([
    'Napa Valley has great wine.',
    'Laravel is a PHP framework.',
])->generate();

$response->embeddings;
// → [[0.123, 0.456, ...], [0.789, 0.012, ...]]

// Override provider/model/dimensions
$response = Embeddings::for(['Napa Valley has great wine.'])
    ->dimensions(1536)
    ->generate(Lab::OpenAI, 'text-embedding-3-small');
```

### Caching

Embedding generation costs money and time. Cache aggressively for inputs that repeat:

```php
// Global default (config/ai.php)
'caching' => [
    'embeddings' => [
        'cache' => true,
        'store' => env('CACHE_STORE', 'database'),
    ],
],

// Per-request
$response = Embeddings::for([...])->cache()->generate();
$response = Embeddings::for([...])->cache(seconds: 3600)->generate();

// Via Stringable
Str::of('...')->toEmbeddings(cache: true);
Str::of('...')->toEmbeddings(cache: 3600);
```

## Storing in the Database

### Setup pgvector

```php
// In a migration
Schema::ensureVectorExtensionExists();
```

### Vector Column

```php
Schema::create('documents', function (Blueprint $table) {
    $table->id();
    $table->foreignIdFor(User::class)->constrained()->restrictOnDelete();
    $table->string('title');
    $table->text('content');
    $table->vector('embedding', dimensions: 1536)->index();  // HNSW index
    $table->timestamps();
});
```

**Always add the `->index()`** for any vector column you'll query. HNSW makes similarity search fast at scale; without it you'll do brute-force scans.

### Model Cast

```php
class Document extends Model
{
    protected function casts(): array
    {
        return [
            'embedding' => 'array',
        ];
    }
}
```

### Populating Embeddings

A typical pattern: generate the embedding on save (or in a queued job for large content):

```php
// app/Actions/CreateDocumentAction.php
public function execute(CreateDocumentData $data): Document
{
    $embedding = Str::of($data->content)->toEmbeddings(cache: true);

    return Document::create([
        'user_id' => $this->auth->userId(),
        'title' => $data->title,
        'content' => $data->content,
        'embedding' => $embedding,
    ]);
}
```

For large or batch ingestion, queue it:

```php
class GenerateEmbeddingsJob implements ShouldQueue
{
    #[\Illuminate\Queue\Attributes\Tries(3)]
    public function __construct(public int $documentId) {}

    public function handle(): void
    {
        $document = Document::findOrFail($this->documentId);
        $document->update([
            'embedding' => Str::of($document->content)->toEmbeddings(cache: true),
        ]);
    }
}
```

## Querying Embeddings

### Primary API: `whereVectorSimilarTo()`

Pass either a string (auto-generates the query embedding) or a precomputed vector:

```php
use App\Models\Document;

// String query — embedding generated for you
$documents = Document::query()
    ->whereVectorSimilarTo('embedding', 'best wineries in Napa Valley')
    ->limit(10)
    ->get();

// With minimum similarity threshold (0.0 = identical, 1.0 = farthest)
$documents = Document::query()
    ->whereVectorSimilarTo('embedding', $queryEmbedding, minSimilarity: 0.4)
    ->limit(10)
    ->get();

// Scoped to user (always do this for user-owned data)
$documents = Document::query()
    ->where('user_id', auth()->id())
    ->whereVectorSimilarTo('embedding', $query)
    ->limit(10)
    ->get();
```

### Lower-Level Methods

For advanced control (sorting by distance, exposing score, custom distance metrics):

```php
$documents = Document::query()
    ->select('*')
    ->selectVectorDistance('embedding', $queryEmbedding, as: 'distance')
    ->whereVectorDistanceLessThan('embedding', $queryEmbedding, maxDistance: 0.3)
    ->orderByVectorDistance('embedding', $queryEmbedding)
    ->limit(10)
    ->get();

// Each row now has $document->distance available
```

### Reranking

For two-stage retrieval (broad vector pull → narrow reranking), use a reranker:

```php
use Laravel\Ai\Reranking;

// Top 50 by vector similarity, then rerank to top 10 by relevance
$candidates = Document::query()
    ->whereVectorSimilarTo('embedding', $query)
    ->limit(50)
    ->get();

$reranked = $candidates->rerank('content', $query)->take(10);

// Or with multiple fields
$reranked = $candidates->rerank(['title', 'content'], $query);

// Or a custom builder
$reranked = $candidates->rerank(
    fn ($doc) => $doc->title.': '.$doc->content,
    $query,
);
```

Reranking is more accurate than pure vector similarity but adds another API call. Use when relevance quality matters more than latency.

**Supported reranker providers:** Cohere, Jina, VoyageAI.

## RAG Pattern: Vector Search as Agent Tool

The most common use of embeddings is RAG (retrieval-augmented generation). Wire a vector search as a tool on an AI Agent:

```php
use Laravel\Ai\Tools\SimilaritySearch;

class DocumentAssistant implements Agent, HasTools
{
    public function __construct(public User $user) {}

    public function instructions(): string
    {
        return 'Answer the user\'s questions using only the documents available to them. If you can\'t find relevant info, say so.';
    }

    public function tools(): iterable
    {
        return [
            SimilaritySearch::usingModel(
                model: Document::class,
                column: 'embedding',
                minSimilarity: 0.5,
                limit: 5,
                query: fn ($q) => $q->where('user_id', $this->user->id),  // scope to user!
            ),
        ];
    }
}
```

The agent's model decides when to search and what to search for. The tool runs the vector query and feeds results back to the model.

## Configuration

Default provider for embeddings in `config/ai.php`:

```php
'embeddings' => [
    'model' => 'text-embedding-3-small',
    'provider' => 'openai',
],
```

Common embedding models:

| Provider | Model | Dimensions | Notes |
|----------|-------|------------|-------|
| OpenAI | `text-embedding-3-small` | 1536 (or smaller via `dimensions:`) | Cheap, fast, general-purpose |
| OpenAI | `text-embedding-3-large` | 3072 | Higher quality, more $$ |
| Voyage AI | `voyage-3` | 1024 | Strong RAG quality |
| Cohere | `embed-v3` | 1024 | Multi-lingual |

Use the same model for storing AND querying — embeddings from different models are NOT comparable.

## Compliance

- ⚠️ **Embeddings can leak content.** A vector is a lossy representation, but with enough vectors + the embedding model, source text can sometimes be reconstructed (especially for short or sensitive text).
- ⚠️ **Always scope queries to authorized users.** Vector search is a powerful join across all rows — without `->where('user_id', ...)` you'll leak data.
- ⚠️ **Hash or remove PII before embedding** when the text isn't itself user content (e.g., when embedding system-generated descriptions).

## Key Points

- Generate via `Str::of(...)->toEmbeddings()` (one) or `Embeddings::for([...])->generate()` (batch)
- Cache aggressively — embedding generation has real cost
- Store in `vector(N)` column with `->index()` (HNSW)
- Cast as `'array'` on the model
- Query with `->whereVectorSimilarTo('embedding', $query)`
- ALWAYS scope user-owned queries with `WHERE user_id = ...`
- Use `SimilaritySearch::usingModel(...)` as an agent tool for RAG
- Use reranking for two-stage retrieval when quality matters
- Generate + query with the SAME embedding model

## When to Use

✅ **Embeddings + vector search for:**
- Semantic search ("find articles about X")
- RAG (give an LLM access to user-owned data)
- Recommendations ("more like this")
- Deduplication / clustering (group similar items)
- Classification (compare to labeled exemplars)

❌ **Not embeddings for:**
- Keyword search (use full-text search, MySQL `FULLTEXT` / Postgres `tsvector`)
- Structured queries (use SQL `WHERE`)
- Exact lookups (use unique indexes)
- Cost-sensitive read paths at huge scale (embedding cost adds up)
