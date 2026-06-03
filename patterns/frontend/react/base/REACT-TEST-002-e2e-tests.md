# REACT-TEST-002-e2e-tests

## Pattern

End-to-end tests use **Playwright** — real browser, full app boot, real network (or staging API). Tests live in `tests/e2e/`. E2E tests are the slowest and most expensive layer; keep them focused on critical user journeys.

## Stack

- **Playwright Test** — runner, browser automation, fixtures, retries
- **Page Objects** — encapsulate selectors + actions for each screen

## Structure

```typescript
import { test, expect } from '@playwright/test';
import { BillsPage } from './page-objects/BillsPage';
import { loginAs } from './helpers/auth';

test.describe('Bill creation flow', () => {
  test.beforeEach(async ({ page }) => {
    await loginAs(page, 'test@example.com');
  });

  test('user creates a new bill', async ({ page }) => {
    const bills = new BillsPage(page);
    await bills.goto();

    await bills.clickAdd();
    await bills.fillForm({ name: 'New Internet', amount: 75 });
    await bills.submitForm();

    await expect(bills.toast).toContainText('Bill created successfully');
    await expect(bills.card('New Internet')).toBeVisible();
  });

  test('shows validation errors for invalid input', async ({ page }) => {
    const bills = new BillsPage(page);
    await bills.goto();

    await bills.clickAdd();
    await bills.submitForm();  // empty

    await expect(bills.error('name')).toBeVisible();
    await expect(bills.error('amount')).toBeVisible();
  });
});
```

## Page Objects

Each screen gets a Page Object encapsulating selectors and actions:

```typescript
// tests/e2e/page-objects/BillsPage.ts
import { type Page, type Locator } from '@playwright/test';

export class BillsPage {
  readonly page: Page;
  readonly addButton: Locator;
  readonly formNameInput: Locator;
  readonly formAmountInput: Locator;
  readonly formSubmit: Locator;
  readonly toast: Locator;

  constructor(page: Page) {
    this.page = page;
    this.addButton = page.getByTestId('bills-page-add');
    this.formNameInput = page.getByTestId('user-form-name');
    this.formAmountInput = page.getByTestId('user-form-amount');
    this.formSubmit = page.getByRole('button', { name: /save/i });
    this.toast = page.getByRole('status');
  }

  async goto() {
    await this.page.goto('/bills');
    await this.page.waitForLoadState('networkidle');
  }

  async clickAdd() {
    await this.addButton.click();
  }

  async fillForm(data: { name: string; amount: number }) {
    await this.formNameInput.fill(data.name);
    await this.formAmountInput.fill(String(data.amount));
  }

  async submitForm() {
    await this.formSubmit.click();
  }

  card(name: string): Locator {
    return this.page.locator('[data-testid="bill-card"]', { hasText: name });
  }

  error(field: string): Locator {
    return this.page.locator(`[data-testid="user-form-${field}"]`).locator('+ .error');
  }
}
```

## Auth in beforeEach

Most authenticated flows need login. Provide a helper:

```typescript
// tests/e2e/helpers/auth.ts
import type { Page } from '@playwright/test';

export async function loginAs(page: Page, email: string) {
  await page.goto('/login');
  await page.getByLabel(/email/i).fill(email);
  await page.getByLabel(/password/i).fill('password');
  await page.getByRole('button', { name: /sign in/i }).click();
  await page.waitForURL(/\/dashboard|\/bills/);
}
```

For faster tests, consider auth via the API (skip the UI login form):

```typescript
export async function loginViaApi(page: Page, email: string) {
  const response = await page.request.post('/api/auth/login', {
    data: { email, password: 'password' },
  });
  const { token } = await response.json();
  await page.context().addCookies([{ name: 'session', value: token, domain: 'localhost', path: '/' }]);
}
```

## Selectors (Playwright)

Prefer role/text queries (accessible), fall back to `data-testid`:

```typescript
page.getByRole('button', { name: /sign in/i })
page.getByLabel(/email/i)
page.getByText(/welcome/i)
page.getByTestId('bill-card')          // escape hatch
```

NEVER use CSS classes for E2E selectors — they break when styling changes.

## Waiting

Playwright auto-waits for elements to be visible/enabled before interaction. Avoid explicit `waitForTimeout` (flaky). Use:

```typescript
await page.waitForLoadState('networkidle');
await page.waitForURL(/\/bills/);
await expect(locator).toBeVisible();  // auto-retries
```

## Responsive Testing

```typescript
test.describe('Mobile layout', () => {
  test.use({ viewport: { width: 375, height: 812 } });

  test('shows mobile menu', async ({ page }) => {
    // ...
  });
});
```

## Conventions

- Tests in `tests/e2e/`, files named `{flow}.spec.ts`
- Page Objects in `tests/e2e/page-objects/`
- Auth helpers in `tests/e2e/helpers/`
- One `test.describe` per user flow
- `beforeEach` for login + setup
- `data-testid` for elements without semantic identity
- Real or staging backend; don't mock the API in E2E (defeats the purpose)

## Running Tests

```bash
npm run test:e2e                       # all E2E
npm run test:e2e -- bill-creation      # specific spec
npm run test:e2e -- --headed           # see the browser
npm run test:e2e -- --ui               # Playwright UI mode (great for debugging)
```

## What E2E Should Cover

E2E tests are slow — be selective:
- Critical user journeys (signup → first feature → key action)
- Cross-component flows (form → toast → list refresh)
- Auth + permission boundaries
- Regression coverage for production bugs

NOT for: every component variant (component tests cover that), edge cases in validation (use unit tests), every page (just the ones that matter most).

## Key Points

- Playwright + Page Objects + auth helpers
- Real backend (or staging); don't mock the API
- Query by role/text first; testid as fallback
- Use Playwright's auto-waiting; avoid `waitForTimeout`
- Keep E2E focused on critical journeys
- See REACT-TEST-001 for component-level (Vitest) testing
