# VUE-TEST-002-e2e-tests

## Pattern

End-to-end tests use **Playwright**. Tests live in `tests/e2e/`. They drive a real browser against the running app and verify full user flows.

## Stack

- **Playwright** — browser automation, assertions, fixtures
- **Configured browsers** — Chromium (default); Firefox/WebKit available

## Structure

```typescript
import { test, expect } from '@playwright/test';

test.describe('Bills page', () => {
  test('user can list and view bills', async ({ page }) => {
    await page.goto('/bills');

    // Wait for the bill cards to load
    const cards = page.locator('[data-testid="bill-card"]');
    await expect(cards.first()).toBeVisible();

    // Click into a bill
    await cards.first().click();
    await expect(page).toHaveURL(/\/bills\/[A-Z0-9]{26}/);
    await expect(page.locator('h1')).toContainText('Bill Details');
  });

  test('user can create a new bill', async ({ page }) => {
    await page.goto('/bills');

    await page.locator('[data-testid="add-bill"]').click();
    await expect(page.locator('[data-testid="bill-form-dialog"]')).toBeVisible();

    await page.locator('[data-testid="bill-name-input"]').fill('Electricity');
    await page.locator('[data-testid="bill-amount-input"]').fill('150');
    await page.locator('[data-testid="bill-submit"]').click();

    await expect(page.locator('text=Bill created successfully')).toBeVisible();
    await expect(page.locator('text=Electricity')).toBeVisible();
  });
});
```

## Selectors

Use `data-testid` attributes — never CSS classes or text content (text breaks with i18n changes):

```vue
<q-btn data-testid="bill-submit" type="submit">Save</q-btn>
```

```typescript
await page.locator('[data-testid="bill-submit"]').click();
```

For dynamic content (like a list of bills), prefix with the type:

```vue
<BillCard v-for="bill in bills" :data-testid="`bill-card-${bill.id}`" />
```

```typescript
await page.locator('[data-testid^="bill-card-"]').first().click();
```

## Authentication

Most pages require login. Use a setup file or `beforeEach` to authenticate:

```typescript
test.beforeEach(async ({ page }) => {
  await page.goto('/login');
  await page.fill('[data-testid="email"]', 'test@example.com');
  await page.fill('[data-testid="password"]', 'password');
  await page.click('[data-testid="login-submit"]');
  await page.waitForURL('/'); // wait for redirect after login
});
```

For better performance, use Playwright's `globalSetup` to authenticate once and reuse the storage state. See Playwright docs for `storageState`.

## Waiting

Prefer explicit waits over `waitForTimeout`:

```typescript
// ✅ Good — waits for the element to be visible
await expect(page.locator('[data-testid="bill-card"]')).toBeVisible();

// ✅ Good — waits for navigation
await page.waitForURL(/\/bills\/.+/);

// ❌ Bad — arbitrary delay
await page.waitForTimeout(2000);
```

## Test Organization

| File pattern | Purpose |
|--------------|---------|
| `landing.spec.ts` | Public landing page flows |
| `auth.spec.ts` | Login, signup, password reset |
| `bills.spec.ts` | Bill management flows |
| `households.spec.ts` | Household flows |

One file per top-level domain or user journey.

## Page Object Pattern (Optional)

For complex flows reused across tests, encapsulate in a Page Object:

```typescript
// tests/e2e/pages/BillsPage.ts
import type { Page } from '@playwright/test';

export class BillsPage {
  constructor(private readonly page: Page) {}

  async goto() {
    await this.page.goto('/bills');
  }

  async createBill(name: string, amount: number) {
    await this.page.locator('[data-testid="add-bill"]').click();
    await this.page.locator('[data-testid="bill-name-input"]').fill(name);
    await this.page.locator('[data-testid="bill-amount-input"]').fill(amount.toString());
    await this.page.locator('[data-testid="bill-submit"]').click();
  }
}
```

```typescript
test('user can create a bill', async ({ page }) => {
  const bills = new BillsPage(page);
  await bills.goto();
  await bills.createBill('Electricity', 150);
});
```

Use Page Objects when a flow is repeated in 3+ tests.

## Responsive Tests

Use viewport sizing to test mobile flows:

```typescript
test('mobile: hero is visible', async ({ page }) => {
  await page.setViewportSize({ width: 375, height: 667 });
  await page.goto('/');
  await expect(page.locator('.HeroSection')).toBeVisible();
});
```

## Conventions

- One `test.describe(...)` per major flow
- Use `data-testid` selectors exclusively
- Auth via `beforeEach` or `storageState`
- Explicit waits (`expect`, `waitForURL`) — never arbitrary timeouts
- Page Objects for flows used in 3+ tests
- Test happy paths, edge cases, error cases

## Running Tests

```bash
# All E2E tests
npm run test:e2e

# Headed mode (see the browser)
npm run test:e2e -- --headed

# Single file
npm run test:e2e -- bills.spec.ts

# Debug mode (Playwright Inspector)
npm run test:e2e -- --debug
```

## Key Points

- Playwright drives a real browser end-to-end
- Use `data-testid` selectors, never CSS classes or text
- Authenticate via `beforeEach` or shared `storageState`
- Use explicit waits (`expect`, `waitForURL`) — no `waitForTimeout`
- Page Objects for repeated flows
- Test by user journey: one `.spec.ts` file per major flow
- Component-level tests go in Vitest (see VUE-TEST-001)
