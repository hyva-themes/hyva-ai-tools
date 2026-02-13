# Page Object Patterns

Code patterns for Playwright page objects interacting with Hyvä's Alpine.js components.

## Page Object Structure

Every page object follows this pattern:

```typescript
import type { Page, Locator } from '@playwright/test';

// 1. Selectors object at module top level
const selectors = {
  pageTitle: '#maincontent h1.page-title',
  successMessages: '#messages .message.success',
  qtyInputField: 'input[data-role="cart-item-qty"]',
  cartSpinner: '#cart-totals svg.animate-spin',
  // ... more selectors
};

// 2. Class with readonly page
export class CartPage {
  readonly page: Page;

  constructor(page: Page) {
    this.page = page;
  }

  // 3. Navigation methods
  async goto() {
    await this.page.goto('/checkout/cart');
    await this.page.waitForLoadState('domcontentloaded');
  }

  // 4. Action methods (async, return void)
  async changeQuantity(index: number, newQty: number) {
    const input = this.page.locator(selectors.qtyInputField).nth(index);
    await input.clear();
    await input.fill(String(newQty));
    await input.press('Enter');
  }

  // 5. Getter properties returning Locator
  get pageTitle(): Locator {
    return this.page.locator(selectors.pageTitle);
  }

  get successMessages(): Locator {
    return this.page.locator(selectors.successMessages);
  }

  // 6. Helper methods for reading values
  async getGrandTotal(): Promise<string> {
    return await this.page.locator(selectors.grandTotal).textContent() ?? '';
  }
}
```

**Key conventions:**
- Selectors as a `const` object at module scope (not in a separate file)
- `readonly page: Page` in constructor
- Action methods are `async` and return `void`
- Getters return `Locator` (not `Promise<Locator>`)
- Text-reading helpers return `Promise<string>`

## hover() Parent then Click Child for Submenus

Hyvä's navigation uses Alpine.js `x-show` on submenus, triggered by mouse hover. You must hover to reveal the element before clicking.

```typescript
async openSubcategory(categoryName: string, subcategoryName: string) {
    await this.page.getByRole('link', { name: categoryName }).hover();
    await this.page.getByRole('navigation', { name: 'Main menu' })
      .getByRole('link', { name: subcategoryName }).click();
}
```

## waitForLoadState() After Form Submits

After navigating or submitting forms, wait for the new page to load:

```typescript
async goToProfile() {
    await this.page.getByRole('link', { name: 'Account Information' }).click();
    await this.page.waitForLoadState('domcontentloaded');
}

async login(email: string, password: string) {
    await this.page.locator('#email').fill(email);
    await this.page.locator('#pass').fill(password);
    await this.page.locator('#pass').press('Enter');
    await this.page.waitForLoadState('domcontentloaded');
}
```

## waitForURL() When Actions Redirect

```typescript
async logout() {
    await this.page.goto('/customer/account/logout');
    await this.page.waitForURL('**/logoutSuccess');
}

async addProductToCart(productUrl: string) {
    await this.page.goto(productUrl);
    await this.page.locator(selectors.addToCartButton).click();
    await this.page.waitForURL('**/checkout/cart');
}
```
