# FILAMENT-001-resources

## Pattern

A **Filament Resource** is the full CRUD interface for an Eloquent model inside a Filament admin panel. One resource class declares two schemas — a **form** (create + edit) and a **table** (the list view) — plus its **pages** and any **relation managers**. Filament renders the panel UI from these declarations; you write PHP, not Blade or JavaScript.

> **Filament 4** (current) is assumed here. Key differences from v3: `form()` receives a `Filament\Schemas\Schema` (not `Forms\Form`) and returns it via `->components()` (not `->schema()`); actions live in a unified `Filament\Actions\*` namespace; table actions are `->recordActions()` / `->toolbarActions()` (were `->actions()` / `->bulkActions()`). On a v3 project, use `Forms\Form` + `->schema()` + `Tables\Actions\*` + `->actions()`/`->bulkActions()` instead.

## Structure

**Scaffold:**
```bash
php artisan make:filament-resource Order
# common flags:
php artisan make:filament-resource Order --generate       # infer form+table from the schema
php artisan make:filament-resource Order --view           # add a read-only View page
php artisan make:filament-resource Order --soft-deletes
```

This generates `app/Filament/Resources/Orders/OrderResource.php`, its `Pages/` dir (List/Create/Edit), and — by default in v4 — separate **schema classes** under `Orders/Schemas/OrderForm.php` and `Orders/Tables/OrdersTable.php` (keeping the resource class thin). You can also define `form()`/`table()` inline as shown below. Match wherever the project's panel keeps resources (a panel can set a custom namespace).

**Resource skeleton (inline form + table):**
```php
<?php

declare(strict_types=1);

namespace App\Filament\Resources\Orders;

use App\Filament\Resources\Orders\Pages;
use App\Models\Order;
use Filament\Actions\BulkActionGroup;
use Filament\Actions\DeleteBulkAction;
use Filament\Actions\EditAction;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;
use UnitEnum;

class OrderResource extends Resource
{
    protected static ?string $model = Order::class;

    protected static string|\BackedEnum|null $navigationIcon = 'heroicon-o-shopping-cart';

    public static function form(Schema $schema): Schema
    {
        return $schema->components([
            TextInput::make('reference')
                ->required()
                ->maxLength(255),

            Select::make('status')
                ->options([
                    'pending' => 'Pending',
                    'paid' => 'Paid',
                    'cancelled' => 'Cancelled',
                ])
                ->required(),

            TextInput::make('total')
                ->numeric()
                ->prefix('$')
                ->required(),
        ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('reference')->searchable(),
                TextColumn::make('status')->badge(),
                TextColumn::make('total')->money('usd')->sortable(),
                TextColumn::make('created_at')
                    ->dateTime()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                SelectFilter::make('status')
                    ->options([
                        'pending' => 'Pending',
                        'paid' => 'Paid',
                        'cancelled' => 'Cancelled',
                    ]),
            ])
            ->recordActions([
                EditAction::make(),
            ])
            ->toolbarActions([
                BulkActionGroup::make([
                    DeleteBulkAction::make(),
                ]),
            ]);
    }

    public static function getRelations(): array
    {
        return [
            // RelationManagers\LineItemsRelationManager::class,
        ];
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListOrders::route('/'),
            'create' => Pages\CreateOrder::route('/create'),
            'edit' => Pages\EditOrder::route('/{record}/edit'),
        ];
    }
}
```

The form-component and table-column/action vocabulary is covered in the forms-and-tables vocabulary.

## Form schema

`form()` returns a `Schema` whose `->components([...])` holds field components. Common ones (import each from `Filament\Forms\Components\*`):

- `TextInput::make('name')->required()->maxLength(255)` — `->email()`, `->numeric()`, `->password()`, `->prefix()/->suffix()`.
- `Select::make('status')->options([...])` — `->relationship('author', 'name')` to pick a related record; `->searchable()`, `->preload()`.
- `Textarea`, `RichEditor`, `MarkdownEditor` for long text.
- `DatePicker` / `DateTimePicker`.
- `Toggle::make('is_active')`, `Checkbox`, `Radio`.
- `FileUpload::make('attachment')`.

Group with layout components from `Filament\Schemas\Components\*` — `Section::make('Details')->schema([...])`, `Grid::make(2)->schema([...])`, `Fieldset`, `Tabs`.

## Table

`table()` declares columns, filters, and actions:

- **Columns** (`Filament\Tables\Columns\*`): `TextColumn`, `IconColumn`, `ImageColumn`, `ToggleColumn`, `SelectColumn`. Chain `->searchable()`, `->sortable()`, `->badge()`, `->money('usd')`, `->dateTime()`, `->toggleable()`.
- **Filters** (`Filament\Tables\Filters\*`): `SelectFilter::make('status')->options([...])`, `TernaryFilter`, `Filter::make('verified')->query(fn (Builder $q) => $q->whereNotNull('verified_at'))`.
- **Record actions** (per-row, `Filament\Actions\*`): `EditAction`, `ViewAction`, `DeleteAction`, or custom `Action::make(...)` — passed to `->recordActions([...])`.
- **Toolbar / bulk actions:** `->toolbarActions([BulkActionGroup::make([DeleteBulkAction::make()])])`.

## Relation managers

Manage a model's related records on its edit/view page. Scaffold:

```bash
php artisan make:filament-relation-manager OrderResource lineItems reference
```

The generated manager has its own `form()` and `table()` (same component vocabulary). Register it in the resource's `getRelations()`.

## Authorization

A resource defers to the model's **policy** automatically — `viewAny`, `view`, `create`, `update`, `delete` gate the corresponding pages/actions. Define a policy for the model; Filament respects it without extra wiring. Override per-resource with methods like `static::canCreate()` only when you need to diverge from the policy.

## Key Points

- One resource = a model's form + table + pages (+ relation managers); scaffold with `make:filament-resource`.
- `form(Schema $schema): Schema` returns `->components([...])`; v4 generates separate `Schemas/`/`Tables/` classes by default.
- `table()` declares columns + filters + `->recordActions()` + `->toolbarActions()`.
- `getPages()` wires List/Create/Edit (+ View) routes; `getRelations()` registers relation managers.
- Authorization comes from the model's **policy** automatically.
- `--generate` infers the form + table from the migration/schema as a starting point.

## Compliance

- ⚠️ **Define a model policy.** Without one, resource access falls back to whatever the panel's auth allows — easy to over-expose admin CRUD. The policy is the access boundary.
- ⚠️ **Validate at the form layer** (`->required()`, `->maxLength()`, `->unique(ignoreRecord: true)`, `->rules([...])`) — don't rely on DB constraints alone for user-facing errors.
- ⚠️ **Scope what an admin can see** if the panel is multi-tenant or role-limited — apply a query scope (`getEloquentQuery()`) rather than exposing every row.
