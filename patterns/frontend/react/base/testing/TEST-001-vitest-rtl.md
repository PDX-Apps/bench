# Testing — Vitest + Testing Library

Unit and component tests with **Vitest** + **`@testing-library/react`** + **`@testing-library/user-event`**. Test what the user sees and does. End-to-end (Playwright) ships as the `playwright` addon.

## Component test

```tsx
// components/UserCard.test.tsx
import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { describe, it, expect, vi } from 'vitest'
import { UserCard } from './UserCard'

const user = { id: '1', firstName: 'Ada', lastName: 'Lovelace', email: 'ada@x.io', createdAt: '' }

describe('UserCard', () => {
  it('renders the full name', () => {
    render(<UserCard user={user} />)
    expect(screen.getByRole('heading', { name: 'Ada Lovelace' })).toBeInTheDocument()
  })

  it('calls onEdit with the user when Edit is clicked', async () => {
    const onEdit = vi.fn()
    render(<UserCard user={user} onEdit={onEdit} />)
    await userEvent.click(screen.getByRole('button', { name: 'Edit' }))
    expect(onEdit).toHaveBeenCalledWith(user)
  })
})
```

## Hook test

```tsx
// hooks/useDisclosure.test.ts
import { renderHook, act } from '@testing-library/react'
import { describe, it, expect } from 'vitest'
import { useDisclosure } from './useDisclosure'

it('toggles', () => {
  const { result } = renderHook(() => useDisclosure())
  expect(result.current.isOpen).toBe(false)
  act(() => result.current.toggle())
  expect(result.current.isOpen).toBe(true)
})
```

## Conventions

- **Query by role/label/text** (`getByRole`, `getByLabelText`) — accessible, resilient. Use `data-testid` only as a last resort.
- **`userEvent`** for interactions (not `fireEvent`) — it models real user behaviour.
- **Test behaviour, not implementation**: rendered output + callback calls, not internal state.
- **Mock the boundary** (HTTP client / query) with `vi.mock`; wrap components that use queries in a test `QueryClientProvider`.
- **`findBy*` / `waitFor`** for async UI; `renderHook` + `act` for hooks.
- **Co-locate** as `*.test.tsx` (or under `tests/` if that's the project convention).

## Don't

- Don't assert on internal state or implementation details.
- Don't query by brittle class names.
- Don't hit the network — mock the HTTP boundary.
- Don't put e2e flows here — that's `playwright`.
