# VUE-TEST-001-component-tests

## Pattern

Component unit tests use **Vitest** + **@vue/test-utils**. Tests live in `tests/unit/` (top-level) or co-located with components (`__tests__/`).

## Stack

- **Vitest** — test runner, assertions
- **@vue/test-utils** — `mount()`, `shallowMount()` for component mounting
- **UI library plugin** — required only if the component uses a UI library (Quasar, Vuetify, etc.). Discover from existing tests.

## Structure

```typescript
import { describe, it, expect, beforeEach } from 'vitest';
import { mount, VueWrapper } from '@vue/test-utils';
import { createPinia, setActivePinia } from 'pinia';
import BillCard from 'src/modules/Bill/components/Cards/BillCard.vue';
import type { Bill } from 'src/modules/Bill/models/Bill';

describe('BillCard', () => {
  let wrapper: VueWrapper;

  beforeEach(() => {
    setActivePinia(createPinia());
  });

  it('renders the bill name and amount', () => {
    const bill: Bill = /* construct or factory a Bill */;

    wrapper = mount(BillCard, {
      props: { bill },
    });

    expect(wrapper.text()).toContain(bill.name);
    expect(wrapper.text()).toContain(bill.amount.toString());
  });

  it('emits click when card is clicked', async () => {
    const bill = /* ... */;
    wrapper = mount(BillCard, {
      props: { bill },
    });

    await wrapper.trigger('click');

    expect(wrapper.emitted('click')).toBeTruthy();
    expect(wrapper.emitted('click')?.[0]).toEqual([bill]);
  });
});
```

## Required Setup

Components using Pinia need an active store:

```typescript
beforeEach(() => {
  setActivePinia(createPinia());
});
```

Components using a UI library need its plugin (only when the project uses one):

```typescript
import { Quasar } from 'quasar';  // example — only if the project uses Quasar

mount(MyComponent, {
  global: {
    plugins: [Quasar],
  },
});
```

Discover the right setup by reading an existing test in the project.

## Mocking Services

For components that import services, mock the module:

```typescript
import { vi } from 'vitest';

vi.mock('src/modules/Bill/services/BillService', () => ({
  BillService: {
    list: vi.fn().mockResolvedValue([]),
    create: vi.fn(),
  },
}));
```

If the project uses a DI container or framework wrapper for service access, mock that helper instead. Discover from sibling tests.

## Testing User Interactions

```typescript
it('opens the dialog when add button clicked', async () => {
  wrapper = mount(BillsPage, { /* ... */ });

  await wrapper.find('[data-testid="add-bill"]').trigger('click');

  expect(wrapper.findComponent(BillFormDialog).props('modelValue')).toBe(true);
});
```

Use `data-testid` attributes for stable selectors — never CSS classes (those change with styling).

## Testing Async Tasks

When the component uses the project's async-task helper, mock it to control resolution:

```typescript
const mockTask = {
  run: vi.fn().mockResolvedValue(undefined),
  isActive: { value: false },
  errors: { value: [] },
};

vi.mock('src/composables/task', () => ({
  task: () => mockTask,
}));

it('shows loading state while task is active', async () => {
  mockTask.isActive.value = true;
  wrapper = mount(BillsPage, { /* ... */ });
  await wrapper.vm.$nextTick();

  expect(wrapper.find('[data-testid="loading-skeleton"]').exists()).toBe(true);
});
```

## Conventions

- One `describe('ComponentName', ...)` per component
- Each `it(...)` tests one behavior
- Use `data-testid` for selectors
- Reset Pinia in `beforeEach`
- Mock services and the project's async-task helper — never let real network calls or production helpers run in unit tests
- Use factories or stubs for model data (avoid hand-constructing every Bill)
- Test BEHAVIOR (renders X when prop Y, emits Z on click) — not implementation

## Running Tests

```bash
# All unit tests
npm run test:unit

# Watch mode
npm run test:unit -- --watch

# Single file
npm run test:unit -- BillCard
```

## Key Points

- Vitest + @vue/test-utils
- Register the UI library plugin only if the project uses one (discover from existing tests)
- Reset Pinia in `beforeEach`
- Mock services + the project's async-task helper — don't let them run real
- Use `data-testid` for selectors
- Test behavior, not implementation
- See VUE-TEST-002 for E2E (Playwright) testing
