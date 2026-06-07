# Testing — Playwright (end-to-end)

End-to-end tests that drive a real browser through user flows. Complements the unit/component tests ([TEST-001]) — use e2e for critical paths (auth, checkout, the core journey), not for every component.

## A flow test

```ts
// e2e/users.spec.ts
import { test, expect } from '@playwright/test'

test('an admin can create a user', async ({ page }) => {
  await page.goto('/users')
  await page.getByRole('link', { name: 'New user' }).click()

  await page.getByLabel('First name').fill('Ada')
  await page.getByLabel('Email').fill('ada@example.com')
  await page.getByRole('button', { name: 'Save' }).click()

  await expect(page.getByRole('row', { name: /ada@example.com/ })).toBeVisible()
})
```

## Page Object (for reused flows)

```ts
// e2e/pages/LoginPage.ts
import type { Page } from '@playwright/test'

export class LoginPage {
  constructor(private page: Page) {}
  async login(email: string, password: string) {
    await this.page.goto('/login')
    await this.page.getByLabel('Email').fill(email)
    await this.page.getByLabel('Password').fill(password)
    await this.page.getByRole('button', { name: 'Sign in' }).click()
  }
}
```

## Auth setup (sign in once, reuse state)

```ts
// e2e/auth.setup.ts — a setup project saves storageState; other projects reuse it
import { test as setup } from '@playwright/test'
setup('authenticate', async ({ page }) => {
  await new LoginPage(page).login('admin@example.com', 'secret')
  await page.context().storageState({ path: 'e2e/.auth/admin.json' })
})
```

## Conventions

- **Role/label locators** (`getByRole`, `getByLabel`) — accessible + resilient. `data-testid` only when semantics aren't enough.
- **`web-server`** in `playwright.config.ts` boots the app (`npm run dev`/`preview`) before tests; `baseURL` set so `page.goto('/path')` is relative.
- **Page Objects** for flows reused across specs; keep specs readable.
- **Auth once** via a setup project + `storageState`; don't log in in every test.
- **Auto-waiting**: rely on web-first assertions (`await expect(locator).toBeVisible()`); avoid manual sleeps.
- **Independent tests**: each resets its own state (fresh data/seed); no ordering dependencies.

## Don't

- Don't e2e-test what a component test already covers — e2e is for cross-page journeys.
- Don't use brittle CSS/text selectors or fixed `waitForTimeout`.
- Don't share mutable state between tests.

## See also

- [TEST-001] (unit/component) · [playwright.dev](https://playwright.dev)
