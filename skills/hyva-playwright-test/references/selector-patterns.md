# Selector Patterns — Before / After

Concrete examples of selector patterns for Hyvä's Alpine.js DOM. Each pattern prefers user-facing locators per [Playwright best practices](https://playwright.dev/docs/locators).

## Hidden Message Elements

Bare `.message` selectors match hidden Alpine `x-show` elements — scope to `#messages`.

```typescript
// BEFORE — matches hidden Alpine x-show elements (strict mode error)
await expect(page.locator('.message.success')).toContainText('Item added');
await expect(page.locator('.message-error')).toContainText('Error');

// AFTER — scoped to #messages container
await expect(page.locator('#messages .message.success')).toContainText('Item added');
await expect(page.locator('#messages .message-error, #messages .message.error')).toContainText('Error');
```

## Text Ambiguity — getByText() to getByRole()

In Magento, the same text appears in headings, links, breadcrumbs, and screen-reader spans. `getByText()` matches all of them.

```typescript
// BEFORE — "Account Information" appears in heading, sidebar link, and breadcrumb
await page.getByText('Account Information').click();

// AFTER — targets specifically the link
await page.getByRole('link', { name: 'Account Information' }).click();
```

## Scoped Text Searches

Product names and other text appear in multiple page regions (recently viewed, cross-sells, main content).

```typescript
// BEFORE — may match product name in sidebar/footer/cross-sells
await expect(page.getByText(productName)).toBeVisible();

// AFTER — scoped to main content area
await expect(page.locator('#maincontent').getByText(productName)).toBeVisible();
```

## Checkbox Labels — getByText() to getByLabel()

Form checkboxes have associated `<label>` elements. `getByText()` may match other instances of the same text.

```typescript
// BEFORE — "Change Password" text exists in multiple DOM locations
await page.getByText('Change Password').click();
await expect(page.getByText('Change Password')).not.toBeChecked();

// AFTER — targets the checkbox input via its label
await page.getByLabel('Change Password').check();
await expect(page.getByLabel('Change Password')).not.toBeChecked();
```

## Submenu Navigation — hover() Before Click

Hidden `x-show` submenus must be revealed by hovering before clicking. Using `force: true` or complex CSS selectors bypasses this and leads to flaky tests.

```typescript
// WRONG — force-clicks a hidden submenu element
const subCategory = page.locator(
  'div.lg\\:block > nav > ul li:nth-child(2) > ul > li:nth-child(1) > a'
);
await subCategory.click({ force: true });

// RIGHT — hover parent to reveal Alpine x-show submenu, then click
await page.getByRole('link', { name: 'Women' }).hover();
await page.getByRole('navigation', { name: 'Main menu' })
  .getByRole('link', { name: 'Tops' }).click();
```
