# Testing — Vitest (unit + component)

Unit and component tests with **Vitest** + **`@vue/test-utils`**. This is the base testing layer. End-to-end (Playwright) ships as the `bench-playwright` addon.

## Component test

```ts
// components/UserCard.spec.ts
import { mount } from '@vue/test-utils'
import { describe, it, expect, vi } from 'vitest'
import UserCard from './UserCard.vue'

const user = { id: '1', firstName: 'Ada', lastName: 'Lovelace', email: 'ada@x.io', createdAt: '' }

describe('UserCard', () => {
  it('renders the full name', () => {
    const wrapper = mount(UserCard, { props: { user } })
    expect(wrapper.get('[data-testid="name"]').text()).toBe('Ada Lovelace')
  })

  it('emits edit with the user when Edit is clicked', async () => {
    const wrapper = mount(UserCard, { props: { user } })
    await wrapper.get('[data-testid="edit"]').trigger('click')
    expect(wrapper.emitted('edit')?.[0]).toEqual([user])
  })
})
```

## Composable / unit test

```ts
// composables/useDisclosure.spec.ts
import { describe, it, expect } from 'vitest'
import { useDisclosure } from './useDisclosure'

describe('useDisclosure', () => {
  it('toggles', () => {
    const { isOpen, toggle } = useDisclosure()
    expect(isOpen.value).toBe(false)
    toggle()
    expect(isOpen.value).toBe(true)
  })
})
```

## Conventions

- **Co-locate** as `*.spec.ts` next to the unit under test (or under `tests/` if that's the project's convention — match it).
- **Select by `data-testid`**, not CSS classes or text that changes — resilient to styling/copy changes.
- **Test behaviour, not internals**: rendered output, emitted events, what the user sees — not private refs.
- **Mock the boundary** (the HTTP client / query) with `vi.mock`, not the component's internals. For components using queries, mount with a test `QueryClient` (`VueQueryPlugin`) or mock the data composable.
- **`flushPromises()` / `await`** trigger before asserting on async updates.
- **Arrange-act-assert**, one behaviour per `it`.

## Don't

- Don't assert on internal component state (`wrapper.vm.someRef`) — assert on output/emits.
- Don't select by brittle class names or copy.
- Don't hit the network — mock the HTTP boundary.
- Don't put e2e flows here — that's `bench-playwright`.

## See also

- [COMPONENT-001](../components/COMPONENT-001-conventions.md) · [COMPOSABLE-001](../composables/COMPOSABLE-001-conventions.md) · addon: `bench-playwright`
