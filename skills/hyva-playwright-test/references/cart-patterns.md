# Cart Patterns

Patterns for cart page and mini cart interactions in Hyvä's Alpine.js storefront.

## Cart Spinner Wait Pattern

The cart totals recalculate asynchronously. A Tailwind `animate-spin` SVG spinner appears and disappears. The `.catch(() => {})` on the visible wait is critical — the spinner may appear and disappear too quickly to catch.

```typescript
async waitForCartUpdate() {
    // Wait for spinner to appear (may already be gone — catch silently)
    await this.page.locator(selectors.cartSpinner)
      .waitFor({ state: 'visible', timeout: 5_000 })
      .catch(() => {});
    // Wait for spinner to disappear (longer timeout for server calculation)
    await this.page.locator(selectors.cartSpinner)
      .waitFor({ state: 'hidden', timeout: 15_000 });
}
```

Usage:

```typescript
await cartPage.changeQuantity(0, 3);
await cartPage.waitForCartUpdate();
const newTotal = await cartPage.getGrandTotal();
```

## changeQuantity() — Cart Page vs Mini Cart

**Cart page** — fill + Enter (stays on same page):

```typescript
async changeQuantity(index: number, newQty: number) {
    const input = this.page.locator(selectors.qtyInputField).nth(index);
    await input.clear();
    await input.fill(String(newQty));
    await input.press('Enter');
}
```

**Mini cart** — navigates to product page via edit button, changes qty, clicks Add to Cart:

```typescript
async changeQuantity(newQty: string): Promise<void> {
    await this.slider.locator(selectors.miniCartEditProductButton).click();
    await this.page.waitForLoadState('domcontentloaded');
    await this.qtyInputField.clear();
    await this.qtyInputField.fill(newQty);
    await this.addToCartButton.click();
    await this.page.waitForLoadState('domcontentloaded');
}
```
