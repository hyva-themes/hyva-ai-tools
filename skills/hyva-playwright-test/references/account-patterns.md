# Account Patterns

Patterns for customer account page interactions in Hyvä's Alpine.js storefront.

## waitFor() After Alpine Checkbox Reveal

The account edit page uses Alpine.js `x-show` to reveal password fields after checking a checkbox. Fill actions race against Alpine's state update without an explicit wait.

```typescript
// BROKEN — fills password field before Alpine reveals it
async changePassword(currentPw: string, newPw: string) {
    const form = this.page.locator(selectors.changePasswordForm);
    await form.getByLabel('Change Password').check();
    await form.locator(selectors.currentPasswordInput).fill(currentPw);
    // ❌ newPasswordInput may not be visible yet
}

// FIXED — wait for Alpine x-show to reveal the field
async changePassword(currentPw: string, newPw: string) {
    const form = this.page.locator(selectors.changePasswordForm);
    await form.getByLabel('Change Password').check();
    // Wait for Alpine to process x-show toggle
    await form.locator(selectors.newPasswordInput).waitFor({ state: 'visible' });
    await form.locator(selectors.currentPasswordInput).fill(currentPw);
    await form.locator(selectors.newPasswordInput).fill(newPw);
    await form.locator(selectors.newPasswordConfirmationInput).fill(newPw);
    await form.locator(selectors.newPasswordConfirmationInput).press('Enter');
    await this.page.waitForLoadState('domcontentloaded');
}
```
