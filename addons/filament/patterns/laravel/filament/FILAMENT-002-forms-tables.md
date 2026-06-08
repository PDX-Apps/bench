# FILAMENT-002-forms-tables

## Pattern

This is the component vocabulary a Filament Resource (`<PLUGIN_ROOT>/patterns-built/laravel/filament/FILAMENT-001-resources.md`) draws on — **form components**, **layout**, **table columns**, **filters**, and **actions** — in depth. The same vocabulary is reused everywhere: resources, relation managers, action modal forms, custom Livewire pages.

## Form components

```php
use Filament\Forms;

Forms\Components\TextInput::make('reference')
    ->required()
    ->maxLength(255)
    ->unique(ignoreRecord: true);        // ignore current row on edit

Forms\Components\TextInput::make('total')
    ->numeric()
    ->minValue(0)
    ->prefix('$');

Forms\Components\Select::make('status')
    ->options([
        'pending' => 'Pending',
        'paid' => 'Paid',
        'cancelled' => 'Cancelled',
    ])
    ->default('pending')
    ->required();

Forms\Components\Select::make('product_id')
    ->relationship('product', 'name')    // BelongsTo: option list from related model
    ->searchable()
    ->preload()
    ->required();

Forms\Components\Textarea::make('notes')->rows(4)->maxLength(1000);
Forms\Components\RichEditor::make('description');
Forms\Components\DateTimePicker::make('shipped_at');
Forms\Components\Toggle::make('is_priority');

Forms\Components\FileUpload::make('attachment')
    ->disk('public')
    ->directory('invoices')
    ->acceptedFileTypes(['application/pdf'])
    ->maxSize(2048);                     // KB
```

### Reactivity + conditional fields

```php
Forms\Components\Select::make('type')
    ->options(['physical' => 'Physical', 'digital' => 'Digital'])
    ->live();                            // re-render dependent fields on change

Forms\Components\TextInput::make('weight')
    ->numeric()
    ->visible(fn (Forms\Get $get) => $get('type') === 'physical');
```

Use `->live()` to make a field trigger re-evaluation, and `Forms\Get`/`Forms\Set` closures (`->visible()`, `->disabled()`, `->afterStateUpdated()`) to react.

## Layout components

Wrap fields for structure — these don't map to data, they organize the form:

```php
use Filament\Forms;

Forms\Components\Section::make('Order details')
    ->description('Reference + status')
    ->schema([
        Forms\Components\TextInput::make('reference'),
        Forms\Components\Select::make('status')->options([/* ... */]),
    ])
    ->columns(2);

Forms\Components\Grid::make(3)->schema([/* fields */]);

Forms\Components\Tabs::make('Tabs')->tabs([
    Forms\Components\Tabs\Tab::make('General')->schema([/* ... */]),
    Forms\Components\Tabs\Tab::make('Shipping')->schema([/* ... */]),
]);
```

## Table columns

```php
use Filament\Tables;

Tables\Columns\TextColumn::make('reference')
    ->searchable()
    ->sortable()
    ->copyable();

Tables\Columns\TextColumn::make('status')
    ->badge()
    ->color(fn (string $state) => match ($state) {
        'paid' => 'success',
        'cancelled' => 'danger',
        default => 'warning',
    });

Tables\Columns\TextColumn::make('total')->money('usd')->sortable();
Tables\Columns\TextColumn::make('product.name')->label('Product');   // dot-notation across a relation
Tables\Columns\TextColumn::make('created_at')->dateTime()->sortable()
    ->toggleable(isToggledHiddenByDefault: true);

Tables\Columns\IconColumn::make('is_priority')->boolean();
Tables\Columns\ImageColumn::make('thumbnail')->circular();

Tables\Columns\ToggleColumn::make('is_active');    // editable inline
Tables\Columns\SelectColumn::make('status')        // editable inline
    ->options(['pending' => 'Pending', 'paid' => 'Paid'])
    ->rules(['required']);
```

`searchable()` adds a search field; `sortable()` adds column sorting; `toggleable()` lets users show/hide; `->money()`, `->dateTime()`, `->badge()`, `->boolean()` format the value.

## Filters

```php
use Filament\Tables;
use Illuminate\Database\Eloquent\Builder;

Tables\Filters\SelectFilter::make('status')
    ->options(['pending' => 'Pending', 'paid' => 'Paid', 'cancelled' => 'Cancelled'])
    ->multiple();

Tables\Filters\SelectFilter::make('product')
    ->relationship('product', 'name');

Tables\Filters\TernaryFilter::make('is_priority');

Tables\Filters\Filter::make('high_value')
    ->query(fn (Builder $query): Builder => $query->where('total', '>=', 1000));
```

## Actions

Per-row actions, header actions, and bulk actions all share the same `Action` base:

```php
use Filament\Tables;

// Per-row
->actions([
    Tables\Actions\ViewAction::make(),
    Tables\Actions\EditAction::make(),
    Tables\Actions\DeleteAction::make(),

    Tables\Actions\Action::make('markPaid')
        ->icon('heroicon-o-banknotes')
        ->requiresConfirmation()
        ->visible(fn ($record) => $record->status !== 'paid')
        ->action(fn ($record) => $record->markPaid()),
])

// Bulk
->bulkActions([
    Tables\Actions\BulkActionGroup::make([
        Tables\Actions\DeleteBulkAction::make(),

        Tables\Actions\BulkAction::make('markPaid')
            ->requiresConfirmation()
            ->action(fn ($records) => $records->each->markPaid()),
    ]),
])
```

A custom `Action` can collect input via its own modal form — `->form([TextInput::make('reason')->required()])` — and receive it as `->action(function (array $data, $record) { ... })`.

## Key Points

- Form fields: `TextInput`, `Select` (`->relationship()` for related records), `Textarea`/`RichEditor`, `DateTimePicker`, `Toggle`, `FileUpload` — validate with `->required()`, `->maxLength()`, `->unique(ignoreRecord: true)`, `->rules([...])`.
- Layout (`Section`, `Grid`, `Tabs`) organizes fields and doesn't map to data.
- Reactivity: `->live()` + `Forms\Get`/`Set` closures (`->visible()`, `->afterStateUpdated()`).
- Columns: `TextColumn`/`IconColumn`/`ImageColumn`/`ToggleColumn`/`SelectColumn`; `->searchable()`, `->sortable()`, `->badge()`, `->money()`, `->dateTime()`, dot-notation for relations.
- Filters: `SelectFilter`, `TernaryFilter`, custom `Filter` with a `->query()` closure.
- Actions share one base; `EditAction`/`DeleteAction` prebuilt, custom `Action` with modal `->form()` + `->action()`; bulk actions wrap in `BulkActionGroup`.

## Compliance

- ⚠️ **Mutating custom actions need their own authorization** — gate with `->visible()`/`->authorize()` and confirm with `->requiresConfirmation()`. A bulk "markPaid" or "refund" must check the same policy a controller would.
- ⚠️ **`unique(ignoreRecord: true)`** on edit forms — without it, editing a record trips its own unique constraint.
- ⚠️ **Constrain `FileUpload`** with `acceptedFileTypes()` + `maxSize()`; never accept arbitrary types/sizes into a public disk.
