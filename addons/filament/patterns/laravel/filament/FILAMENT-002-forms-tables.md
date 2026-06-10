# FILAMENT-002-forms-tables

## Pattern

This is the component vocabulary a Filament Resource draws on — **form components**, **layout**, **table columns**, **filters**, and **actions** — in depth. The same vocabulary is reused everywhere: resources, relation managers, action modal forms, custom Livewire pages.

> **Filament 4 namespaces** (assumed here): form components `Filament\Forms\Components\*`; layout components `Filament\Schemas\Components\*` (`Section`, `Grid`, `Tabs`); reactivity utilities `Filament\Schemas\Components\Utilities\{Get, Set}`; table columns `Filament\Tables\Columns\*`; filters `Filament\Tables\Filters\*`; **all actions** (record/bulk/header) `Filament\Actions\*`. Table actions are `->recordActions()` / `->toolbarActions()`. (On a v3 project these are `Forms\Components\*`, `Tables\Actions\*`, `->actions()`/`->bulkActions()`.)

## Form components

```php
// v4: import each component, e.g. use Filament\Forms\Components\TextInput;

TextInput::make('reference')
    ->required()
    ->maxLength(255)
    ->unique(ignoreRecord: true);        // ignore current row on edit

TextInput::make('total')
    ->numeric()
    ->minValue(0)
    ->prefix('$');

Select::make('status')
    ->options([
        'pending' => 'Pending',
        'paid' => 'Paid',
        'cancelled' => 'Cancelled',
    ])
    ->default('pending')
    ->required();

Select::make('product_id')
    ->relationship('product', 'name')    // BelongsTo: option list from related model
    ->searchable()
    ->preload()
    ->required();

Textarea::make('notes')->rows(4)->maxLength(1000);
RichEditor::make('description');
DateTimePicker::make('shipped_at');
Toggle::make('is_priority');

FileUpload::make('attachment')
    ->disk('public')
    ->directory('invoices')
    ->acceptedFileTypes(['application/pdf'])
    ->maxSize(2048);                     // KB
```

### Reactivity + conditional fields

```php
Select::make('type')
    ->options(['physical' => 'Physical', 'digital' => 'Digital'])
    ->live();                            // re-render dependent fields on change

TextInput::make('weight')
    ->numeric()
    ->visible(fn (Get $get) => $get('type') === 'physical');
```

Use `->live()` to make a field trigger re-evaluation, and `Get`/`Set` closures (`->visible()`, `->disabled()`, `->afterStateUpdated()`) to react.

## Layout components

Wrap fields for structure — these don't map to data, they organize the form:

```php
// v4: import each component, e.g. use Filament\Forms\Components\TextInput;

Section::make('Order details')
    ->description('Reference + status')
    ->schema([
        TextInput::make('reference'),
        Select::make('status')->options([/* ... */]),
    ])
    ->columns(2);

Grid::make(3)->schema([/* fields */]);

Tabs::make('Tabs')->tabs([
    Tabs\Tab::make('General')->schema([/* ... */]),
    Tabs\Tab::make('Shipping')->schema([/* ... */]),
]);
```

## Table columns

```php
// v4: use Filament\Tables\Columns\TextColumn; filters Filament\Tables\Filters\*; actions Filament\Actions\*

TextColumn::make('reference')
    ->searchable()
    ->sortable()
    ->copyable();

TextColumn::make('status')
    ->badge()
    ->color(fn (string $state) => match ($state) {
        'paid' => 'success',
        'cancelled' => 'danger',
        default => 'warning',
    });

TextColumn::make('total')->money('usd')->sortable();
TextColumn::make('product.name')->label('Product');   // dot-notation across a relation
TextColumn::make('created_at')->dateTime()->sortable()
    ->toggleable(isToggledHiddenByDefault: true);

IconColumn::make('is_priority')->boolean();
ImageColumn::make('thumbnail')->circular();

ToggleColumn::make('is_active');    // editable inline
SelectColumn::make('status')        // editable inline
    ->options(['pending' => 'Pending', 'paid' => 'Paid'])
    ->rules(['required']);
```

`searchable()` adds a search field; `sortable()` adds column sorting; `toggleable()` lets users show/hide; `->money()`, `->dateTime()`, `->badge()`, `->boolean()` format the value.

## Filters

```php
// v4: use Filament\Tables\Columns\TextColumn; filters Filament\Tables\Filters\*; actions Filament\Actions\*
use Illuminate\Database\Eloquent\Builder;

SelectFilter::make('status')
    ->options(['pending' => 'Pending', 'paid' => 'Paid', 'cancelled' => 'Cancelled'])
    ->multiple();

SelectFilter::make('product')
    ->relationship('product', 'name');

TernaryFilter::make('is_priority');

Filter::make('high_value')
    ->query(fn (Builder $query): Builder => $query->where('total', '>=', 1000));
```

## Actions

Per-row actions, header actions, and bulk actions all share the same `Action` base:

```php
// v4: use Filament\Tables\Columns\TextColumn; filters Filament\Tables\Filters\*; actions Filament\Actions\*

// Per-row
->recordActions([
    ViewAction::make(),
    EditAction::make(),
    DeleteAction::make(),

    Action::make('markPaid')
        ->icon('heroicon-o-banknotes')
        ->requiresConfirmation()
        ->visible(fn ($record) => $record->status !== 'paid')
        ->action(fn ($record) => $record->markPaid()),
])

// Bulk
->toolbarActions([
    BulkActionGroup::make([
        DeleteBulkAction::make(),

        BulkAction::make('markPaid')
            ->requiresConfirmation()
            ->action(fn ($records) => $records->each->markPaid()),
    ]),
])
```

A custom `Action` can collect input via its own modal form — `->form([TextInput::make('reason')->required()])` — and receive it as `->action(function (array $data, $record) { ... })`.

## Key Points

- Form fields: `TextInput`, `Select` (`->relationship()` for related records), `Textarea`/`RichEditor`, `DateTimePicker`, `Toggle`, `FileUpload` — validate with `->required()`, `->maxLength()`, `->unique(ignoreRecord: true)`, `->rules([...])`.
- Layout (`Section`, `Grid`, `Tabs`) organizes fields and doesn't map to data.
- Reactivity: `->live()` + `Get`/`Set` closures (`->visible()`, `->afterStateUpdated()`).
- Columns: `TextColumn`/`IconColumn`/`ImageColumn`/`ToggleColumn`/`SelectColumn`; `->searchable()`, `->sortable()`, `->badge()`, `->money()`, `->dateTime()`, dot-notation for relations.
- Filters: `SelectFilter`, `TernaryFilter`, custom `Filter` with a `->query()` closure.
- Actions share one base; `EditAction`/`DeleteAction` prebuilt, custom `Action` with modal `->form()` + `->action()`; bulk actions wrap in `BulkActionGroup`.

## Compliance

- ⚠️ **Mutating custom actions need their own authorization** — gate with `->visible()`/`->authorize()` and confirm with `->requiresConfirmation()`. A bulk "markPaid" or "refund" must check the same policy a controller would.
- ⚠️ **`unique(ignoreRecord: true)`** on edit forms — without it, editing a record trips its own unique constraint.
- ⚠️ **Constrain `FileUpload`** with `acceptedFileTypes()` + `maxSize()`; never accept arbitrary types/sizes into a public disk.
