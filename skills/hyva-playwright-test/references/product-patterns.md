# Product Patterns

Patterns for product page interactions in Hyvä's Alpine.js storefront.

## Bundle Product Quantities

Fill + blur (no submit, Alpine recalculates on blur):

```typescript
async function setBundleQuantities(
  page: Page,
  qtyOrFn: number | ((index: number) => number),
) {
  const inputs = page.locator('input.qty.bundle-option-qty');
  const count = await inputs.count();
  for (let idx = 0; idx < count; idx++) {
    const input = inputs.nth(idx);
    const qty = typeof qtyOrFn === 'function' ? qtyOrFn(idx) : qtyOrFn;
    await input.clear();
    await input.fill(String(qty));
    await input.blur(); // blur() triggers Alpine recalculation
  }
  // Callers should use web-first assertions to wait for Alpine to settle
}
```

## Gallery Images

Hyvä's product gallery contains multiple `<img>` elements: a hidden placeholder (with `itemprop="image"`), the active visible image (with `x-show`), and thumbnails. Use the `itemprop` attribute to uniquely target the main product image.

```typescript
// BEFORE — matches 3 images (placeholder, active, thumbnail), strict mode error
await page.locator('#gallery img').getAttribute('src');

// BEFORE — :visible works but is discouraged
await page.locator('#gallery img:visible').getAttribute('src');

// AFTER — itemprop uniquely identifies the main product image
await page.locator('#gallery img[itemprop="image"]').getAttribute('src');

// ALTERNATIVE — alt text when product name is known
await page.getByRole('img', { name: 'Didi Sport Watch' }).click();
```
