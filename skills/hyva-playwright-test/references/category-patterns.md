# Category Patterns

Patterns for category listing page interactions in Hyvä's Alpine.js storefront.

## scrollIntoViewIfNeeded() for x-defer="intersect"

Hyvä's category filters use `x-defer="intersect"` — the Alpine.js component only initializes when scrolled into the viewport. You must scroll the element into view before interacting.

```typescript
// BROKEN — element not initialized because never scrolled into viewport
async filterByColorRed() {
    await this.page.locator('.filter-options-title').filter({ hasText: 'Color' }).click();
    await this.selectColorRed.click();
}

// FIXED — scroll triggers x-defer="intersect" initialization
async filterByColorRed() {
    const colorButton = this.page.getByRole('button', { name: 'Color filter' });
    await colorButton.scrollIntoViewIfNeeded();
    await colorButton.click();
    await this.selectColorRed.click();
    await this.page.waitForLoadState('domcontentloaded');
}
```

## Filter Buttons

Hyvä renders category filters as buttons inside headings with `x-defer="intersect"`.

```typescript
// BEFORE (Luma CSS selectors)
await page.locator('.filter-options-title').filter({ hasText: 'Color' }).click();

// AFTER — scroll into view (triggers x-defer), then click role-based selector
const colorButton = page.getByRole('button', { name: 'Color filter' });
await colorButton.scrollIntoViewIfNeeded();
await colorButton.click();
```

## Pagination

Hyvä uses semantic ARIA markup for pagination instead of Luma's `ul.pages-items`.

```typescript
// BEFORE (Luma CSS selectors)
await page.locator('ul.pages-items li a').first().click();
const activePage = page.locator('ul.pages-items li strong');

// AFTER (Hyvä ARIA roles)
const paginationNav = page.getByRole('navigation', { name: 'pagination' });
await paginationNav.getByRole('link', { name: 'Page 2' }).click();
const activePage = paginationNav.locator('[aria-current="page"]');
```
