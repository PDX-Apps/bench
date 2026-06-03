# DB-004-public-ids

## Pattern

Use public IDs (ULID/UUID) for API exposure while keeping internal auto-increment IDs for database performance.

## Why

**Security:**
- Don't expose internal auto-increment IDs
- Prevents enumeration attacks
- Harder to guess related resources

**Example attack prevented:**
```
// Bad: Auto-increment exposed
GET /api/resources/1
GET /api/resources/2  // Can enumerate all resources
GET /api/resources/3

// Good: Public ID exposed
GET /api/resources/01HQZX...
GET /api/resources/01HQZY...  // Can't enumerate
```

## Implementation

### Migration

```php
Schema::create('{table}', function (Blueprint $table) {
    $table->id();                           // Internal primary key
    $table->publicId();                     // Public-facing identifier (ULID)
    $table->char('code', 6)->unique();      // Optional: human-friendly code
    $table->string('name');
    $table->timestamps();
});
```

**Available drivers** (from PublicId package):
- ULID (default, recommended)
- UUID
- Char (custom length)
- Custom drivers

### Model Setup

```php
class {Model} extends Model
{
    protected $fillable = [];  // Never include public_id or code in fillable

    protected static function boot(): void
    {
        parent::boot();

        static::creating(function ($model) {
            if (empty($model->public_id)) {
                $model->public_id = PublicId::generate();
            }
            if (empty($model->code)) {
                $model->code = static::generateUniqueCode();
            }
        });
    }

    /**
     * Generate a unique 6-character code for the model.
     */
    protected static function generateUniqueCode(): string
    {
        do {
            $code = strtoupper(Str::random(6));
        } while (static::where('code', $code)->exists());

        return $code;
    }

    public function getRouteKeyName(): string
    {
        return 'public_id';
    }
}
```

**Key Points:**
- Use `boot()` with `creating` event to auto-generate on creation
- Use `PublicId::generate()` for public_id (respects config driver)
- Generate unique codes with retry loop
- Never add public_id or code to `$fillable` array
- Use `protected` methods for testability

### API Resource

```php
class {Model}Resource extends JsonResource
{
    public function toArray($request): array
    {
        return [
            'id' => $this->public_id,      // Public ID as "id"
            'code' => $this->code,          // Optional share code
            'name' => $this->name,
            // Internal id is never exposed
        ];
    }
}
```

## When to Use What

### Use `public_id` for:
- ✅ API endpoints (always)
- ✅ External integrations
- ✅ User-facing URLs

### Use `code` for:
- ✅ Human-friendly sharing
- ✅ Short URLs
- ✅ QR codes

### Use `id` (internal) for:
- ✅ Database relationships
- ✅ Internal queries
- ✅ Performance-critical joins
- ❌ Never expose to API

## Benefits

**Performance:**
- Joins on integer `id` (fast)
- Indexes on `public_id` for lookups

**Security:**
- Can't enumerate resources
- Can't guess related IDs
- Prevents timing attacks

**UX:**
- ULID is sortable (contains timestamp)
- `code` is memorable and shareable
- Clean API responses
