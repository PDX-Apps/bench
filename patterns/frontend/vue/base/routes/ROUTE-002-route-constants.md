# ROUTE-002-route-constants

## Pattern

Route names are typed enums exported from `src/modules/{Name}/router/constants.ts`. Components and pages reference these constants instead of hardcoded route name strings — enables refactor safety and IDE autocomplete.

## Structure

```typescript
/**
 * Bill route name constants
 */
export enum BillRoutes {
  LIST = 'bill.list',
  DETAIL = 'bill.detail',
}
```

## Naming Convention

- File: `constants.ts` (in `router/`)
- Enum name: `{Module}Routes` (PascalCase + `Routes` suffix)
- Member names: `SCREAMING_SNAKE_CASE` (`LIST`, `DETAIL`, `EDIT`)
- Member values: `module.action` dot notation, lowercase

## Usage

```typescript
import { BillRoutes } from '../router/constants';
import { useRouter } from 'vue-router';

const router = useRouter();

// Navigation
router.push({ name: BillRoutes.DETAIL, params: { id: bill.id } });

// Route definition
{
  path: '',
  name: BillRoutes.LIST,
  component: () => import('../pages/BillsPage.vue'),
}

// Programmatic access
router.replace({ name: BillRoutes.LIST });
```

## Cross-Module Navigation

Import the target module's enum directly:

```typescript
// In Auth module, navigate to Bills after login
import { BillRoutes } from 'src/modules/Bill/router/constants';

router.push({ name: BillRoutes.LIST });
```

This keeps cross-module references explicit and refactor-safe.

## Why Enums (Not Constants)

- TypeScript's `enum` provides exhaustive type checking when used in `switch` statements
- Better IDE refactor support
- Distinguishable from regular strings in IDE search
- Explicit `string` value for vue-router compatibility

## Anti-Patterns

```typescript
// ❌ Wrong — hardcoded string in navigation
router.push({ name: 'bill.list' });

// ❌ Wrong — hardcoded string in route definition
{ name: 'bill.list', ... }

// ❌ Wrong — exporting individual constants instead of enum
export const BILL_LIST_ROUTE = 'bill.list';
```

```typescript
// ✅ Right
import { BillRoutes } from './constants';
router.push({ name: BillRoutes.LIST });
{ name: BillRoutes.LIST, ... }
```

## Key Points

- One `constants.ts` per module's router folder
- `{Module}Routes` enum, `module.action` value naming
- ALWAYS use the enum — never hardcode route name strings
- Import from `src/modules/{Other}/router/constants` for cross-module nav
- Pairs with ROUTE-001 (route definitions) — names defined here, used there
