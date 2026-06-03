# ENUM-001-i18n-key-enums

## Pattern

Domain enums are `as const` objects whose values are i18n translation keys. This decouples the enum identity (used in code) from the displayed text (which comes from i18n).

## Structure

```typescript
export const AuthStatusEnum = {
  USER_NOT_FOUND: 'auth::status.errors.userNotFound',
  INVALID_CREDENTIALS: 'auth::status.errors.invalidCredentials',
  EMAIL_ALREADY_IN_USE: 'auth::status.errors.emailAlreadyInUse',
  EMAIL_NOT_VERIFIED: 'auth::status.warnings.emailNotVerified',
  LOGOUT_SUCCESS: 'auth::status.success.loggedOut',
  LOGIN_SUCCESS: 'auth::status.success.loggedIn',
  REGISTER_SUCCESS: 'auth::status.success.registered',
} as const;

export type AuthStatusEnum = (typeof AuthStatusEnum)[keyof typeof AuthStatusEnum];
```

## Why This Pattern (Not Numeric or String Enums)

- **Display is i18n-driven** — the displayed message comes from the translation file, not the enum
- **One source of truth for messages** — change the wording in i18n, no code edit needed
- **Locale-aware out of the box** — same key resolves to different text per locale
- **Decouples backend codes from UI** — backend can return `'invalid_credentials'`, frontend maps it to `AuthStatusEnum.INVALID_CREDENTIALS` → translated text

## Usage

```typescript
import { AuthStatusEnum } from '../enums/AuthStatusEnum';
import { useI18n } from 'vue-i18n';

const i18n = useI18n();

// Display the enum's user-facing message
const message = i18n.t(AuthStatusEnum.INVALID_CREDENTIALS);

// Map a backend code to the enum
const code = response.error_code;
const enumValue = AuthStatusEnum[code as keyof typeof AuthStatusEnum];
if (enumValue) {
  showError(i18n.t(enumValue));
}
```

## Type Pattern

The `as const` + `[typeof X][keyof typeof X]` trick gives a string-literal union type:

```typescript
export type AuthStatusEnum = (typeof AuthStatusEnum)[keyof typeof AuthStatusEnum];
// equivalent to:
// 'auth::status.errors.userNotFound' | 'auth::status.errors.invalidCredentials' | ...
```

This lets functions accept "any value of the enum" with full type safety:

```typescript
function showStatus(status: AuthStatusEnum): void {
  showToast(i18n.t(status));
}
```

## Naming Conventions

| Item | Convention | Example |
|------|-----------|---------|
| File | `{Name}Enum.ts` | `AuthStatusEnum.ts`, `OAuthStatusEnum.ts` |
| Location | `src/modules/{Module}/enums/` | `Auth/enums/AuthStatusEnum.ts` |
| Object name | `{Name}Enum` (PascalCase + Enum suffix) | `AuthStatusEnum` |
| Type alias | Same name as object | `export type AuthStatusEnum = ...` |
| Member names | `SCREAMING_SNAKE_CASE` | `INVALID_CREDENTIALS`, `LOGIN_SUCCESS` |
| Member values | i18n key with `module::` namespace | `'auth::status.errors.invalidCredentials'` |

## i18n Key Format

The `module::path.to.key` format is a project convention:
- `module::` prefix marks the namespace (matches a top-level i18n key in that module's translations)
- `path.to.key` matches the dotted key path in the translation file

## When to Use a Different Pattern

- **Pure data classification** (e.g., bill frequency: `monthly`, `weekly`) — use a TypeScript string-literal union directly:
  ```typescript
  export type BillFrequency = 'one_time' | 'weekly' | 'monthly' | ...;
  ```
- **Numeric codes** — use `as const` object with numeric values
- **Backend-aligned status enums** — match the backend's PHP enum value strings

The i18n-key-as-value pattern is specifically for **user-facing status/message enums**.

## Key Points

- `as const` object + `[typeof X][keyof typeof X]` type for i18n key enums
- Member values are i18n keys in `module::path.to.key` format
- `SCREAMING_SNAKE_CASE` for member names
- File naming: `{Name}Enum.ts` in `enums/`
- Use for status/message enums where display is i18n-driven
- For pure data classifications, prefer string-literal unions
