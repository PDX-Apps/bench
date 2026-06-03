# CODE-002-swagger

## Pattern

Use OpenAPI (Swagger) annotations to generate API documentation automatically from code.

## Package

**darkaonline/l5-swagger** - Laravel wrapper for swagger-php

**Documentation URL:** `/api/documentation`

## Why

- Auto-generated API docs from code annotations
- Always up-to-date (docs live with code)
- Interactive testing interface (Swagger UI)
- Type-safe API contracts
- Reduces manual documentation effort

## Required Annotations

**IMPORTANT:** Each class defines its OWN schema. Controllers REFERENCE these schemas, never inline properties.

### Models

All Eloquent models MUST have OpenAPI schema annotations:

```php
use OpenApi\Attributes as OA;

#[OA\Schema(
    schema: 'Household',
    required: ['name'],
    properties: [
        new OA\Property(property: 'id', type: 'string', format: 'ulid', example: '01HQZX9K3V2N8P1R4S6T7V8W9X'),
        new OA\Property(property: 'code', type: 'string', example: 'ABC123'),
        new OA\Property(property: 'name', type: 'string', maxLength: 255, example: 'Family Budget'),
        new OA\Property(property: 'created_at', type: 'string', format: 'date-time'),
        new OA\Property(property: 'updated_at', type: 'string', format: 'date-time'),
    ]
)]
class Household extends Model
{
    use HasFactory, SoftDeletes;
    // ...
}
```

**Key points:**
- Use `#[OA\Schema()]` attribute on class
- Document ALL public properties returned in API responses
- Specify `required` fields
- Add `example` values for better documentation
- Use proper `format` (ulid, date-time, etc.)

### Form Requests

All Form Requests MUST have request body annotations:

```php
use OpenApi\Attributes as OA;

#[OA\Schema(
    schema: 'CreateHouseholdRequest',
    required: ['name'],
    properties: [
        new OA\Property(
            property: 'name',
            type: 'string',
            maxLength: 255,
            example: 'Family Budget',
            description: 'Household name (must be unique per user)'
        ),
    ]
)]
class CreateHouseholdRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:255'],
        ];
    }
}
```

**Key points:**
- Schema name should match request class name
- Document validation constraints (maxLength, pattern, etc.)
- Add descriptions for clarity
- Match `required` array with validation rules

### API Resources

All API Resources MUST have response schema annotations:

```php
use OpenApi\Attributes as OA;

#[OA\Schema(
    schema: 'HouseholdResource',
    properties: [
        new OA\Property(
            property: 'data',
            ref: '#/components/schemas/Household'
        ),
    ]
)]
class HouseholdResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->public_id,
            'code' => $this->code,
            'name' => $this->name,
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ];
    }
}
```

**For collections:**
```php
#[OA\Schema(
    schema: 'HouseholdCollection',
    properties: [
        new OA\Property(
            property: 'data',
            type: 'array',
            items: new OA\Items(ref: '#/components/schemas/Household')
        ),
    ]
)]
class HouseholdCollection extends ResourceCollection
{
    // ...
}
```

### Controllers

All controller methods MUST have operation annotations:

```php
use OpenApi\Attributes as OA;

class HouseholdController extends Controller
{
    #[OA\Get(
        path: '/api/households',
        summary: 'List all households',
        tags: ['Households'],
        parameters: [
            new OA\Parameter(
                name: 'Authorization',
                in: 'header',
                required: true,
                schema: new OA\Schema(type: 'string', example: 'Bearer {token}')
            ),
        ],
        responses: [
            new OA\Response(
                response: 200,
                description: 'Successful operation',
                content: new OA\JsonContent(ref: '#/components/schemas/HouseholdCollection')
            ),
            new OA\Response(response: 401, description: 'Unauthenticated'),
        ]
    )]
    public function index(Request $request)
    {
        // ...
    }

    #[OA\Post(
        path: '/api/households',
        summary: 'Create a new household',
        tags: ['Households'],
        requestBody: new OA\RequestBody(
            required: true,
            content: new OA\JsonContent(
                ref: '#/components/schemas/CreateHouseholdRequest'  // References schema from CreateHouseholdRequest class
            )
        ),
        responses: [
            new OA\Response(
                response: 201,
                description: 'Household created',
                content: new OA\JsonContent(
                    ref: '#/components/schemas/HouseholdResource'  // References schema from HouseholdResource class
                )
            ),
            new OA\Response(response: 401, description: 'Unauthenticated'),
            new OA\Response(response: 422, description: 'Validation failed'),
        ]
    )]
    public function store(CreateHouseholdRequest $request)
    {
        // ...
    }

    #[OA\Get(
        path: '/api/households/{id}',
        summary: 'Get a household by ID',
        tags: ['Households'],
        parameters: [
            new OA\Parameter(
                name: 'id',
                in: 'path',
                required: true,
                schema: new OA\Schema(type: 'string', format: 'ulid')
            ),
        ],
        responses: [
            new OA\Response(
                response: 200,
                description: 'Successful operation',
                content: new OA\JsonContent(ref: '#/components/schemas/HouseholdResource')
            ),
            new OA\Response(response: 401, description: 'Unauthenticated'),
            new OA\Response(response: 403, description: 'Unauthorized'),
            new OA\Response(response: 404, description: 'Not found'),
        ]
    )]
    public function show(Household $household)
    {
        // ...
    }

    #[OA\Put(
        path: '/api/households/{id}',
        summary: 'Update a household',
        tags: ['Households'],
        parameters: [
            new OA\Parameter(
                name: 'id',
                in: 'path',
                required: true,
                schema: new OA\Schema(type: 'string', format: 'ulid')
            ),
        ],
        requestBody: new OA\RequestBody(
            required: true,
            content: new OA\JsonContent(ref: '#/components/schemas/UpdateHouseholdRequest')
        ),
        responses: [
            new OA\Response(
                response: 200,
                description: 'Household updated',
                content: new OA\JsonContent(ref: '#/components/schemas/HouseholdResource')
            ),
            new OA\Response(response: 401, description: 'Unauthenticated'),
            new OA\Response(response: 403, description: 'Unauthorized'),
            new OA\Response(response: 404, description: 'Not found'),
            new OA\Response(response: 422, description: 'Validation failed'),
        ]
    )]
    public function update(UpdateHouseholdRequest $request, Household $household)
    {
        // ...
    }

    #[OA\Delete(
        path: '/api/households/{id}',
        summary: 'Delete a household',
        tags: ['Households'],
        parameters: [
            new OA\Parameter(
                name: 'id',
                in: 'path',
                required: true,
                schema: new OA\Schema(type: 'string', format: 'ulid')
            ),
        ],
        responses: [
            new OA\Response(response: 204, description: 'Household deleted'),
            new OA\Response(response: 401, description: 'Unauthenticated'),
            new OA\Response(response: 403, description: 'Unauthorized'),
            new OA\Response(response: 404, description: 'Not found'),
        ]
    )]
    public function destroy(Household $household)
    {
        // ...
    }
}
```

**Key points:**
- Use `#[OA\Get]`, `#[OA\Post]`, `#[OA\Put]`, `#[OA\Delete]` attributes
- Always include `tags` for grouping
- Document ALL possible responses (200, 201, 204, 401, 403, 404, 422)
- Reference schemas from models/requests/resources (don't duplicate)
- Include Authorization header for protected endpoints
- Use path parameters for resource IDs

## Main API Documentation

Create `app/Http/Controllers/Controller.php` with OpenAPI info:

```php
use OpenApi\Attributes as OA;

#[OA\Info(
    version: '1.0.0',
    title: 'Budget Finder API',
    description: 'API documentation for Budget Finder application'
)]
#[OA\Server(
    url: 'http://localhost',
    description: 'Local development server'
)]
#[OA\SecurityScheme(
    securityScheme: 'bearerAuth',
    type: 'http',
    scheme: 'bearer',
    bearerFormat: 'JWT'
)]
abstract class Controller
{
    //
}
```

## Generating Documentation

```bash
# Generate Swagger JSON
php artisan l5-swagger:generate

# View documentation
# Visit: http://localhost/api/documentation
```

## Anti-Patterns

**❌ Don't inline properties in controllers:**
```php
// ❌ BAD - inlines request properties
#[OA\Post(
    requestBody: new OA\RequestBody(
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: 'name', type: 'string'),
            ]
        )
    )
)]
```

**✅ Do reference schemas from their source classes:**
```php
// ✅ GOOD - references CreateHouseholdRequest schema
#[OA\Post(
    requestBody: new OA\RequestBody(
        content: new OA\JsonContent(
            ref: '#/components/schemas/CreateHouseholdRequest'
        )
    )
)]
```

**❌ Don't duplicate model structure in resources:**
```php
// ❌ BAD - duplicates Household schema
#[OA\Schema(
    schema: 'HouseholdResource',
    properties: [
        new OA\Property(property: 'id', type: 'string'),
        new OA\Property(property: 'name', type: 'string'),
    ]
)]
```

**✅ Do reference existing schemas:**
```php
// ✅ GOOD - references Household schema
#[OA\Schema(
    schema: 'HouseholdResource',
    properties: [
        new OA\Property(property: 'data', ref: '#/components/schemas/Household'),
    ]
)]
```

**❌ Don't skip error responses:**
```php
// ❌ BAD - only documents success
responses: [
    new OA\Response(response: 200, description: 'OK'),
]
```

**✅ Do document all responses:**
```php
// ✅ GOOD - documents all possible responses
responses: [
    new OA\Response(response: 200, description: 'OK'),
    new OA\Response(response: 401, description: 'Unauthenticated'),
    new OA\Response(response: 403, description: 'Unauthorized'),
    new OA\Response(response: 404, description: 'Not found'),
]
```

## Related

- `HTTP-001-resource-controllers` - Controller structure
- `HTTP-002-form-requests` - Validation patterns
- `HTTP-003-standard-responses` - Response formats
- `CODE-001-documentation` - Code documentation standards
