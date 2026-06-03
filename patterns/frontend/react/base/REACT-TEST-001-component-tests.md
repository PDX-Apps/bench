# REACT-TEST-001-component-tests

## Pattern

Component unit tests use **Vitest** + **@testing-library/react**. Tests live in `tests/unit/` (top-level) or co-located with components (`__tests__/`).

The Testing Library philosophy: test components from the user's perspective, not the implementation. Query by role/text/test-id; trigger user events; assert on what the user sees.

## Stack

- **Vitest** — test runner, assertions, mock helpers
- **@testing-library/react** — `render`, `screen`, queries
- **@testing-library/user-event** — realistic user interactions (preferred over `fireEvent`)
- **@testing-library/jest-dom** — extended matchers (`toBeInTheDocument`, etc.)

## Structure

```typescript
import { describe, it, expect, beforeEach, vi } from 'vitest';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { BillCard } from 'src/modules/Bill/components/Cards/BillCard';
import { Bill } from 'src/modules/Bill/models/Bill';

// Stable bill factory for tests
function makeBill(overrides: Partial<Bill> = {}): Bill {
  return Bill.fromApi({
    id: 'B01',
    name: 'Electricity',
    amount: 75.00,
    status: 'unpaid',
    dueDate: '2026-07-01',
    createdAt: '2026-05-01',
    updatedAt: '2026-05-01',
    ...overrides,
  } as any);
}

// Wrapper for components that need react-query / router context
function wrapWithProviders(ui: React.ReactElement) {
  const qc = new QueryClient({ defaultOptions: { queries: { retry: false } } });
  return render(<QueryClientProvider client={qc}>{ui}</QueryClientProvider>);
}

describe('BillCard', () => {
  it('renders the bill name and amount', () => {
    const bill = makeBill({ name: 'Internet', amount: 50 });
    render(<BillCard bill={bill} />);

    expect(screen.getByText('Internet')).toBeInTheDocument();
    expect(screen.getByText(/50/)).toBeInTheDocument();
  });

  it('emits onClick when card is clicked', async () => {
    const user = userEvent.setup();
    const onClick = vi.fn();
    const bill = makeBill();

    render(<BillCard bill={bill} onClick={onClick} />);

    await user.click(screen.getByTestId('bill-card'));

    expect(onClick).toHaveBeenCalledWith(bill);
  });
});
```

## Required Setup

For components using:
- **React Router** — wrap in `<MemoryRouter>` or use `createMemoryRouter`
- **TanStack Query** — wrap in `<QueryClientProvider>` with a fresh `QueryClient` per test
- **Zustand** — reset stores in `beforeEach` (call `useStore.setState(initialState, true)`)
- **i18n** — wrap in `<I18nextProvider i18n={testI18n}>` or mock `useTranslation`
- **UI library plugins** — discover from existing tests (some libs need provider setup)

## Mocking Services

Static service methods are easy to mock:

```typescript
vi.mock('src/modules/Bill/services/BillService', () => ({
  BillService: {
    list: vi.fn().mockResolvedValue([]),
    create: vi.fn(),
    update: vi.fn(),
  },
}));
```

Then assert on mock calls:

```typescript
expect(BillService.create).toHaveBeenCalledWith(expectedPayload);
```

## Mocking TanStack Query

If a component uses `useQuery` internally, prefer providing a real `QueryClient` with prefetched data (more realistic) over mocking `useQuery` itself:

```typescript
const qc = new QueryClient();
qc.setQueryData(['bills', 'list'], [makeBill(), makeBill()]);

render(
  <QueryClientProvider client={qc}>
    <BillsPage />
  </QueryClientProvider>,
);
```

## Testing User Interactions

Use `userEvent` (not `fireEvent`):

```typescript
const user = userEvent.setup();
await user.click(screen.getByRole('button', { name: /save/i }));
await user.type(screen.getByLabelText('Email'), 'test@example.com');
await user.selectOptions(screen.getByLabelText('Country'), 'US');
```

## Testing Async (with TanStack Query)

```typescript
import { waitFor } from '@testing-library/react';

it('shows bills after loading', async () => {
  vi.mocked(BillService.list).mockResolvedValueOnce([makeBill({ name: 'Power' })]);

  wrapWithProviders(<BillsPage />);

  // Initially shows skeleton
  expect(screen.getByTestId('loading-skeleton')).toBeInTheDocument();

  // Eventually shows data
  await waitFor(() => {
    expect(screen.getByText('Power')).toBeInTheDocument();
  });
});
```

## Selectors (in priority order)

1. **`getByRole`** — preferred; matches accessibility tree
2. **`getByLabelText`** — for form inputs
3. **`getByText`** — for static content
4. **`getByTestId`** — last resort for elements without semantic identity (interactive non-button elements, etc.)

`data-testid` is fine but prefer semantic queries when they work. Tests that query by role break less often as styling changes.

## Conventions

- One `describe('ComponentName', ...)` per component
- Each `it(...)` tests one behavior
- Reset Zustand stores in `beforeEach` if the component depends on them
- Mock services — don't let real network calls run
- Use factories (`makeBill`) for model data
- Test BEHAVIOR (renders X when prop Y, calls callback on click) — not implementation

## Running Tests

```bash
npm run test:unit                # all unit tests
npm run test:unit -- --watch     # watch mode
npm run test:unit -- BillCard    # filter by name
```

## Key Points

- Vitest + @testing-library/react + user-event
- Query by role/text first; testid as escape hatch
- Wrap in providers as needed (QueryClient, Router, i18n)
- Mock services; let TanStack Query manage its lifecycle
- Use `userEvent` not `fireEvent`
- Test behavior, not implementation
- See REACT-TEST-002 for E2E (Playwright) testing
