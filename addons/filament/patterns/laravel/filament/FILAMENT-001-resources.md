# FILAMENT-001-resources

## Pattern

A **Filament Resource** is the full CRUD interface for an Eloquent model inside a Filament admin panel. One resource class declares two schemas — a **form** (used on create + edit) and a **table** (the list view) — plus its **pages** and any **relation managers**. Filament renders the panel UI (list / create / edit / view) from these declarations; you write PHP, not Blade or JavaScript.

Reach for a resource whenever you need a back-office screen to manage records of a model.

## Structure

**Scaffold:**
```bash
php artisan make:filament-resource Order
# common flags:
php artisan make:filament-resource Order --generate   # infer form+table from the schema
php artisan make:filament-resource Order --view        # add a read-only View page
php artisan make:filament-resource Order --soft-deletes
```

This generates `app/Filament/Resources/OrderResource.php` plus a `OrderResource/Pages/` directory (List/Create/Edit). Match wherever the project's panel keeps resources (a panel can set a custom namespace).

**Resource skeleton:**
```php
<?php

declare(strict_types=1);

namespace App\Filament\Resources;

use App\Filament\Resources\OrderResource\Pages;
use App\Models\Order;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class OrderResource extends Resource
{
    protected static ?string $model = Order::class;

    protected static ?string $navigationIcon = 'heroicon-o-shopping-cart';

    public static function form(Form $form): Form
    {
        return $form->schema([
            Forms\Components\TextInput::make('reference')
                ->required()
                ->maxLength(255),

            Forms\Components\Select::make('status')
                ->options([
                    'pending' => 'Pending',
                    'paid' => 'Paid',
                    'cancelled' => 'Cancelled',
                ])
                ->required(),

            Forms\Components\TextInput::make('total')
                ->numeric()
                ->prefix('$')
                ->required(),
        ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('reference')
                    ->searchable(),

                Tables\Columns\TextColumn::make('status')
                    ->badge(),

                Tables\Columns\TextColumn::make('total')
                    ->money('usd')
                    ->sortable(),

                Tables\Columns\TextColumn::make('created_at')
                    ->dateTime()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('status')
                    ->options([
                        'pending' => 'Pending',
                        'paid' => 'Paid',
                        'cancelled' => 'Cancelled',
                    ]),
            ])
            ->actions([
                Tables\Actions\EditAction::make(),
            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
                    Tables\Actions\DeleteBulkAction::make(),
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

The form-component and table-column/action vocabulary is covered in depth in `<PLUGIN_ROOT>/patterns-built/laravel/filament/FILAMENT-002-forms-tables.md`.

## Form schema

`form()` returns a schema of field components. Common ones:

- `TextInput::make('name')->required()->maxLength(255)` — `->email()`, `->numeric()`, `->password()`, `->prefix()/->suffix()`.
- `Select::make('status')->options([...])` — `->relationship('author', 'name')` to pick a related record; `->searchable()`, `->preload()`.
- `Textarea`, `RichEditor`, `MarkdownEditor` for long text.
- `DatePicker` / `DateTimePicker`.
- `Toggle::make('is_active')`, `Checkbox`, `Radio`.
- `FileUpload::make('attachment')`.

Group with layout components — `Section::make('Details')->schema([...])`, `Grid::make(2)->schema([...])`, `Fieldset`, `Tabs`. See FILAMENT-002.

## Table

`table()` declares columns, filters, row actions, and bulk actions:

- **Columns:** `TextColumn`, `IconColumn`, `ImageColumn`, `ToggleColumn`, `SelectColumn`. Chain `->searchable()`, `->sortable()`, `->badge()`, `->money('usd')`, `->dateTime()`, `->toggleable()`.
- **Filters:** `SelectFilter::make('status')->options([...])`, `TernaryFilter`, `Filter::make('verified')->query(fn (Builder $q) => $q->whereNotNull('verified_at'))`.
- **Actions** (per-row): `EditAction`, `ViewAction`, `DeleteAction`, or custom `Action::make(...)`.
- **Bulk actions:** wrap in `BulkActionGroup::make([...])`; e.g. `DeleteBulkAction`.

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
- `form()` returns a field-component schema (used by create + edit).
- `table()` declares columns + filters + row/bulk actions for the list view.
- `getPages()` wires List/Create/Edit (+ View) routes; `getRelations()` registers relation managers.
- Authorization comes from the model's **policy** automatically.
- `--generate` infers the form + table from the migration/schema as a starting point.

## Compliance

- ⚠️ **Define a model policy.** Without one, resource access falls back to whatever the panel's auth allows — easy to over-expose admin CRUD. The policy is the access boundary.
- ⚠️ **Validate at the form layer** (`->required()`, `->maxLength()`, `->unique(ignoreRecord: true)`, `->rules([...])`) — don't rely on DB constraints alone for user-facing errors.
- ⚠️ **Scope what an admin can see** if the panel is multi-tenant or role-limited — apply a query scope (`getEloquentQuery()`) rather than exposing every row.
