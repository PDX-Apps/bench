# React Component — conventions

How to write a component in this project: function components + hooks + TypeScript. Styling is project-specific —; the example uses CSS Modules as the zero-config default.

## When

Any reusable piece of UI. Route-level components follow the same anatomy.

## Naming + location

- **PascalCase** component + file: `UserCard.tsx`, `<UserCard />`.
- Match the project's layout — feature folders (`src/features/users/components/UserCard.tsx`) for non-trivial apps, flat (`src/components/UserCard.tsx`) for small. Detect from where siblings live.

## Anatomy — typed function component

```tsx
import { useState } from 'react'
import type { User } from '@/types/user'
import styles from './UserCard.module.css'

interface UserCardProps {
  user: User
  dense?: boolean
  onEdit?: (user: User) => void
}

export function UserCard({ user, dense = false, onEdit }: UserCardProps) {
  const [selected, setSelected] = useState(false)
  const fullName = `${user.firstName} ${user.lastName}`

  return (
    <article className={`${styles.card} ${dense ? styles.dense : ''}`}>
      <input
        type="checkbox"
        checked={selected}
        onChange={(e) => setSelected(e.target.checked)}
        aria-label={`Select ${fullName}`}
      />
      <h3>{fullName}</h3>
      <button type="button" onClick={() => onEdit?.(user)}>Edit</button>
    </article>
  )
}
```

## Conventions

- **Function components**, named export, **typed props interface** (`{Name}Props`). Destructure props with defaults in the signature.
- **Callbacks as props** (`onEdit`, `onSubmit`) — past/imperative names; type them. No event bus.
- **Hooks at the top level**, never conditional. Extract reusable logic into custom hooks.
- **Composition via `children`** + render props/slots-as-props where a parent needs context.
- **Keys** on lists are stable ids, never the array index.
- **Accessibility**: real `<button>`/`<a>`, `aria-*` on icon-only controls, labels on inputs.
- **Presentational** — data fetching lives in query hooks, not inside the component body with `useEffect`.

## Don't

- Don't use class components or default exports for components (named exports aid refactors/imports — match the project if it differs).
- Don't call hooks conditionally or in loops.
- Don't hard-code a styling system — match the project's (Tailwind, CSS Modules, a UI lib)
- Don't use array index as `key`; don't fetch with raw `useEffect` when a query lib is present.
