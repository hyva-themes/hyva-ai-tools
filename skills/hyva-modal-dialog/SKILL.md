---
name: hyva-modal-dialog
description: Create Hyvä Modal Dialogs in Magento 2. This skill should be used when the user wants to add a modal dialog, popup, confirmation dialog, or overlay to a Hyvä theme template. Covers both the inline `<dialog>` + `x-htmldialog` approach and the PHP `Modal` view model API for programmatic/confirmation dialogs. Trigger phrases include "modal dialog", "popup", "confirmation dialog", "hyva modal", "open dialog", "dialog overlay", "x-htmldialog", "hyva.modal".
requires: hyva-alpine-component
---

# Hyvä Modal Dialogs

## Overview

Hyvä Themes provides two complementary approaches for modal dialogs:

1. **Inline `<dialog>` + `x-htmldialog`** — for self-contained modals embedded in a template, where the trigger and modal live in the same Alpine component.
2. **PHP `Modal` View Model + `hyva.modal()`** — for programmatic modals, confirmation dialogs, and modals opened from outside (via events). The PHP view model builds the `<dialog>` HTML; Alpine's `hyva.modal()` provides the `ok()`/`cancel()` confirmation API.

Both approaches use the native HTML `<dialog>` element and Alpine.js — they are fully CSP-compatible. Follow the Alpine.js patterns from the `hyva-alpine-component` skill for all Alpine code.

---

## Approach 1: Inline `<dialog>` + `x-htmldialog`

Use this when the trigger button and modal content are in the same template/component.

### Basic Pattern

```html
<div x-data="initMyModal">
    <button type="button" @click="openDialog">Open Modal</button>

    <dialog
        id="my-modal"
        aria-labelledby="my-modal-title"
        class="open:flex flex-col w-xl"
        x-show="isOpen"
        x-htmldialog="closeDialog"
        x-transition
        closeby="any"
    >
        <div class="p-6">
            <div class="flex gap-2 justify-between items-center mb-4">
                <p id="my-modal-title" class="text-xl">
                    <strong><?= $escaper->escapeHtml(__('Modal Title')) ?></strong>
                </p>
                <button
                    type="button"
                    class="btn bg-transparent border-transparent p-2"
                    @click="closeDialog"
                    aria-label="<?= $escaper->escapeHtmlAttr(__('Close')) ?>"
                >
                    <?= $lucideIcons->xHtml('', 20, 20, ['aria-hidden' => 'true']) ?>
                </button>
            </div>
            <div>
                <!-- Modal content here -->
            </div>
        </div>
    </dialog>
</div>
<script>
    function initMyModal() {
        return {
            isOpen: false,
            openDialog() {
                this.isOpen = true;
            },
            closeDialog() {
                this.isOpen = false;
            }
        }
    }
    window.addEventListener('alpine:init', () => Alpine.data('initMyModal', initMyModal), {once: true})
</script>
<?php $hyvaCsp->registerInlineScript() ?>
```

### `x-htmldialog` Directive Reference

| Syntax | Description |
|--------|-------------|
| `x-htmldialog="closeCallback"` | Standard modal — closes on Escape key and when clicking the backdrop. Calls `closeCallback` on close. |
| `x-htmldialog.modeless="closeCallback"` | Modeless variant — closes on Escape only, not on backdrop click. Used when an external overlay handles backdrop. |

**Supporting attributes:**

| Attribute | Description |
|-----------|-------------|
| `closeby="any"` | Allows closing by clicking the backdrop (used with standard `x-htmldialog`) |
| `x-show="isOpen"` | Controls dialog visibility |
| `x-transition` | Adds enter/leave transitions |
| `x-cloak` | Hides dialog until Alpine initialises |
| `open:flex` | Tailwind class applied when dialog is open |
| `aria-labelledby="id"` | References the heading element ID for accessibility |

---

## Approach 2: PHP `Modal` View Model + `hyva.modal()`

Use this for:
- **Confirmation dialogs** (yes/no with Promise-based result)
- **Modals opened by a window event** (from anywhere on the page)
- **Reusable modal markup** built in PHP and rendered via `<?= $modal ?>`

### PHP Imports

```php
use Hyva\Theme\ViewModel\Modal;

/** @var \Hyva\Theme\ViewModel\Modal $modalViewModel */
$modalViewModel = $viewModels->require(Modal::class);
```

### Building a Modal

```php
$modal = $modalViewModel->createModal()
    ->withContent('<p>Modal body content here</p>')
    ->withAriaLabelledby('my-modal-heading')
    ->addDialogClass('w-xl m-4');

// Render the modal in the template:
echo $modal; // or: <?= /** @noEscape */ $modal ?>
```

### PHP Modal Builder Method Reference

| Method | Description |
|--------|-------------|
| `->withContent(string $html)` | Sets the inner HTML content of the modal |
| `->withAriaLabelledby(string $id)` | Sets `aria-labelledby` on the `<dialog>` for accessibility |
| `->addDialogClass(string $class)` | Appends CSS classes to the `<dialog>` element |
| `->getShowJs()` | Returns a JS expression (string) that programmatically opens the modal and returns a `Promise<boolean>` — resolves `true` when the user clicks ok/confirm, `false` when cancelled |

### Alpine `hyva.modal()` Reference

Spread `hyva.modal()` into your Alpine component to get confirmation dialog support:

```javascript
x-data="Object.assign(hyva.modal(), myComponentData)"
```

| Method/Property | Description |
|-----------------|-------------|
| `ok()` | Closes the modal and resolves the Promise with `true` |
| `cancel()` | Closes the modal and resolves the Promise with `false` |
| `validateSafe()` | Validates the form inside the modal (if present). Returns a Promise resolving to `true` if valid, `false` if not. Useful before calling `ok()` |

---

## Confirmation Dialog Pattern

A confirmation dialog shows content (optionally with a form) and waits for the user to confirm or cancel. The result is returned as a Promise.

```php
<?php
use Hyva\Theme\ViewModel\Modal;
use Hyva\Theme\ViewModel\HyvaCsp;
use Magento\Framework\Escaper;

/** @var Escaper $escaper */
/** @var HyvaCsp $hyvaCsp */

$modalViewModel = $viewModels->require(Modal::class);

$modal = $modalViewModel->createModal()->withContent(<<<END_OF_CONTENT
<div id="confirm-delete-title" class="text-xl mb-4">
    <strong>{$escaper->escapeHtml(__('Confirm Delete'))}</strong>
</div>
<p class="mb-6">{$escaper->escapeHtml(__('Are you sure you want to delete this item?'))}</p>
<div class="flex justify-between gap-2">
    <button @click="ok()" type="button" class="btn btn-primary order-2">
        {$escaper->escapeHtml(__('Delete'))}
    </button>
    <button @click="cancel()" type="button" class="btn order-1">
        {$escaper->escapeHtml(__('Cancel'))}
    </button>
</div>
END_OF_CONTENT
)
->withAriaLabelledby('confirm-delete-title')
->addDialogClass('m-4');
?>
<div
    x-data="Object.assign(hyva.modal(), initDeleteComponent())"
    @delete-item.window="
        itemId = $event.detail.itemId;
        <?= /** @noEscape */ $modal->getShowJs() ?>.then(result => result && deleteItem(itemId));
    "
>
    <?= /** @noEscape */ $modal ?>
</div>
<script>
    function initDeleteComponent() {
        return {
            itemId: null,
            deleteItem(id) {
                // perform delete logic
            }
        }
    }
    window.addEventListener('alpine:init', () => Alpine.data('initDeleteComponent', initDeleteComponent), {once: true})
</script>
<?php $hyvaCsp->registerInlineScript() ?>
```

**Trigger the confirmation from anywhere:**
```javascript
window.dispatchEvent(new CustomEvent('delete-item', { detail: { itemId: 123 } }))
```

### Confirmation Dialog with Form Validation

Use `validateSafe()` to validate a form inside the modal before confirming:

```html
<button @click="validateSafe().then(result => result && ok())" type="button" class="btn btn-primary">
    Confirm
</button>
```

---

## Opening a Modal from Anywhere (Window Events)

To open a modal from outside its Alpine component (e.g., from a different template or a button elsewhere on the page), dispatch a `window` event and handle it in the component.

### Pattern

**Modal template:**
```html
<div x-data="initMyModal" @open-my-modal.window="openDialog">
    <dialog x-show="isOpen" x-htmldialog="closeDialog" x-transition>
        <!-- content -->
    </dialog>
</div>
<script>
    function initMyModal() {
        return {
            isOpen: false,
            openDialog() { this.isOpen = true; },
            closeDialog() { this.isOpen = false; }
        }
    }
    window.addEventListener('alpine:init', () => Alpine.data('initMyModal', initMyModal), {once: true})
</script>
<?php $hyvaCsp->registerInlineScript() ?>
```

**Trigger from anywhere (another template or button):**
```html
<button type="button" @click="$dispatch('open-my-modal')">Open Modal</button>
```

Or in JavaScript:
```javascript
window.dispatchEvent(new Event('open-my-modal'));
// With data:
window.dispatchEvent(new CustomEvent('open-my-modal', { detail: { title: 'Hello' } }));
```

---

## Nested Dialogs

Each nested dialog should be a separate Alpine component with its own state. Use window events to coordinate between them.

```html
<!-- Outer modal -->
<div x-data="initOuterModal">
    <button type="button" @click="openDialog">Open Outer Modal</button>
    <dialog x-show="isOpen" x-htmldialog="closeDialog" x-transition class="w-xl">
        <div class="p-6">
            <p>Outer modal content</p>
            <!-- Open inner modal via event -->
            <button type="button" @click="$dispatch('open-inner-modal')">Open Inner Modal</button>
        </div>
    </dialog>
</div>

<!-- Inner/nested modal (separate component) -->
<div x-data="initInnerModal" @open-inner-modal.window="openDialog">
    <dialog x-show="isOpen" x-htmldialog="closeDialog" x-transition class="w-lg" style="z-index: 60">
        <div class="p-6">
            <p>Inner modal content</p>
            <button type="button" @click="closeDialog">Close Inner</button>
        </div>
    </dialog>
</div>
<script>
    function initOuterModal() {
        return {
            isOpen: false,
            openDialog() { this.isOpen = true; },
            closeDialog() { this.isOpen = false; }
        }
    }
    function initInnerModal() {
        return {
            isOpen: false,
            openDialog() { this.isOpen = true; },
            closeDialog() { this.isOpen = false; }
        }
    }
    window.addEventListener('alpine:init', () => {
        Alpine.data('initOuterModal', initOuterModal);
        Alpine.data('initInnerModal', initInnerModal);
    }, {once: true})
</script>
<?php $hyvaCsp->registerInlineScript() ?>
```

**Key points for nested dialogs:**
- Each modal has its own Alpine component and independent `isOpen` state
- Use `window` events to communicate between components
- Increase `z-index` on inner dialogs to ensure correct stacking (e.g., Tailwind `z-50`, `z-60`)
- Do not share state between unrelated modals

---

## Keyboard Focus & Accessibility

The native HTML `<dialog>` element handles most keyboard behaviour automatically, but these best practices apply:

- Always set `aria-labelledby` pointing to the modal's heading element ID
- Include a visible close button with `aria-label` (e.g., `__('Close')`)
- Focus is automatically trapped inside native `<dialog>` elements
- Escape key closes the dialog via `x-htmldialog`
- Use `hyva.trapFocus(element)` / `hyva.releaseFocus(element)` if you need manual focus trapping (e.g., in non-`<dialog>` overlays)

```javascript
// Manual focus trap for non-dialog overlays
init() {
    hyva.trapFocus(this.$el);
},
closeDialog() {
    hyva.releaseFocus(this.$el);
    this.isOpen = false;
}
```

---

## Required PHP Imports

Always include these imports at the top of a template using modals:

```php
use Hyva\Theme\ViewModel\HyvaCsp;
use Magento\Framework\Escaper;

/** @var Escaper $escaper */
/** @var HyvaCsp $hyvaCsp */
```

For the PHP Modal View Model:
```php
use Hyva\Theme\Model\ViewModelRegistry;
use Hyva\Theme\ViewModel\Modal;

/** @var ViewModelRegistry $viewModels */
$modalViewModel = $viewModels->require(Modal::class);
```

For close button icons (optional, requires LucideIcons):
```php
use Hyva\Theme\ViewModel\LucideIcons;

/** @var LucideIcons $lucideIcons */
$lucideIcons = $viewModels->require(LucideIcons::class);
// Usage: <?= $lucideIcons->xHtml('', 20, 20, ['aria-hidden' => 'true']) ?>
```

---

## Complete Example: Inline Modal

A self-contained, accessible modal with a close button:

```php
<?php
declare(strict_types=1);

use Hyva\Theme\Model\ViewModelRegistry;
use Hyva\Theme\ViewModel\HyvaCsp;
use Hyva\Theme\ViewModel\LucideIcons;
use Magento\Framework\Escaper;
use Magento\Framework\View\Element\Template;

/** @var Template $block */
/** @var Escaper $escaper */
/** @var ViewModelRegistry $viewModels */
/** @var HyvaCsp $hyvaCsp */

/** @var LucideIcons $lucideIcons */
$lucideIcons = $viewModels->require(LucideIcons::class);
?>
<div x-data="initInfoModal">
    <button
        type="button"
        class="btn btn-primary"
        @click="openDialog"
        aria-haspopup="dialog"
    >
        <?= $escaper->escapeHtml(__('Show Info')) ?>
    </button>

    <dialog
        id="info-modal"
        aria-labelledby="info-modal-title"
        class="open:flex flex-col w-xl"
        x-show="isOpen"
        x-htmldialog="closeDialog"
        x-transition
        x-cloak
        closeby="any"
    >
        <div class="p-6">
            <div class="flex gap-2 justify-between items-center mb-4">
                <p id="info-modal-title" class="text-xl">
                    <strong><?= $escaper->escapeHtml(__('Information')) ?></strong>
                </p>
                <button
                    type="button"
                    class="btn bg-transparent border-transparent p-2"
                    @click="closeDialog"
                    aria-label="<?= $escaper->escapeHtmlAttr(__('Close')) ?>"
                >
                    <?= $lucideIcons->xHtml('', 20, 20, ['aria-hidden' => 'true']) ?>
                </button>
            </div>
            <p><?= $escaper->escapeHtml(__('This is the modal content.')) ?></p>
        </div>
    </dialog>
</div>
<script>
    function initInfoModal() {
        return {
            isOpen: false,
            openDialog() {
                this.isOpen = true;
            },
            closeDialog() {
                this.isOpen = false;
            }
        }
    }
    window.addEventListener('alpine:init', () => Alpine.data('initInfoModal', initInfoModal), {once: true})
</script>
<?php $hyvaCsp->registerInlineScript() ?>
```

---

## Decision Guide: Which Approach to Use?

| Use case | Approach |
|----------|----------|
| Simple popup with trigger in same template | Inline `<dialog>` + `x-htmldialog` |
| Confirmation dialog (yes/no, returns result) | PHP `Modal` view model + `hyva.modal()` |
| Modal opened from a window event / any trigger | PHP `Modal` view model + window event listener |
| Modal with form validation before confirm | PHP `Modal` view model + `validateSafe()` |
| Multiple independent modals on one page | Each as a separate inline `<dialog>` component |
| Nested dialogs | Separate Alpine components, communicate via window events |

---

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Forgetting `$hyvaCsp->registerInlineScript()` after `<script>` | Always call it after every `<script>` block |
| Not escaping PHP values in modal content | Use `$escaper->escapeHtml()`, `->escapeJs()`, `->escapeHtmlAttr()` as appropriate |
| Using `hyva.modal()` without PHP `Modal` view model | `hyva.modal()` and `$modal->getShowJs()` work together; use both |
| Forgetting `aria-labelledby` | Always reference the heading ID for screen readers |
| Inner modal behind outer modal (z-index) | Add higher `z-index` class to inner `<dialog>` |
| Mutating state directly in Alpine (CSP) | Extract to methods; see `hyva-alpine-component` skill |
| Not calling `<?= $hyvaCsp->registerInlineScript() ?>` | Required after every inline `<script>` tag |

---

## References

- Authentication popup example: `Magento_Customer/templates/account/authentication-popup.phtml`
- Confirmation dialog example: `Magento_OrderCancellationUi/templates/cancel-order-modal.phtml`
- Gift options dialog example: `Magento_GiftMessage/templates/php-cart/gift-options-container.phtml`
- Alpine CSP patterns: see `hyva-alpine-component` skill
- Focus trap utilities: `hyva.trapFocus()` / `hyva.releaseFocus()` in `hyva.phtml`
- Hyvä Modal Dialogs documentation: https://docs.hyva.io/hyva-themes/view-utilities/modal-dialogs/index.html

<!-- Copyright © Hyvä Themes https://hyva.io. All rights reserved. Licensed under OSL 3.0 -->
