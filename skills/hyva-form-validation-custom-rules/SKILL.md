---
name: hyva-form-validation-custom-rules
description: Create and register custom JavaScript validation rules for Hyvä form validation in Magento 2. This skill should be used when the user wants to add custom validation logic to Hyvä forms, extend the built-in validation rules, register rules via layout XML, or write async validation. Trigger phrases include "custom validation rule", "add validation rule", "hyva form validation", "formValidation.addRule", "custom form validator", "validate field hyva".
---

# Hyvä Form Validation — Custom Rules

## Overview

Hyvä provides a built-in JavaScript form validation library (`hyva.formValidation`) that integrates with Alpine.js. Beyond the built-in rules (`required`, `min`, `max`, `email`, etc.), you can register **custom validation rules** using `hyva.formValidation.addRule()`.

Custom rules are registered globally and are reusable across any form that initialises the `hyva.formValidation` Alpine component.

**Key principle:** Custom rules must be loaded on the page **before** the form that uses them is validated. Use layout XML to inject the rule script at the bottom of the page.

---

## Prerequisites

Ensure the Hyvä form validation layout handle is included on your page:

```xml
<update handle="hyva_form_validation"/>
```

This loads the core `hyva.formValidation` library.

---

## Step 1 — Assign the Rule to the Field (PHP / PHTML)

Use the `data-validate` attribute with your custom rule name as the key:

```html
<input type="text"
       name="vat_number"
       data-validate='{"required": true, "validate-vat-number": true}'
       @change="onChange">
```

With a rule option value (passed as `options` in the callback):

```html
<input type="text"
       name="promo_code"
       data-validate='{"validate-promo-prefix": "SALE"}'
       @change="onChange">
```

---

## Step 2 — Register the Rule JavaScript via Layout XML

Create a dedicated PHTML template for your rule and register it to load before `</body>`:

```xml
<!-- Vendor/Module/view/frontend/layout/default.xml -->
<referenceContainer name="before.body.end">
    <block name="validate-vat-number-rule"
           template="Vendor_Module::validation/validate-vat-number.phtml"/>
</referenceContainer>
```

> **Tip:** Use `default.xml` for site-wide rules, or a page-specific handle (e.g. `checkout_index_index.xml`) for rules only needed on certain pages.

---

## Step 3 — Declare the Rule in a PHTML Template

### Basic Rule Structure

```php
<?php
/** @var \Magento\Framework\View\Element\Template $block */
/** @var \Hyva\Theme\ViewModel\HyvaCsp $hyvaCsp */
$hyvaCsp = $block->getData('hyvaCsp');
?>
<script>
hyva.formValidation.addRule(
    'validate-vat-number',          // Rule name — must match data-validate key
    function (value, options, field) {
        // value   — the current trimmed field value (string)
        // options — the value set in data-validate (true/false/string/number)
        // field   — { element: HTMLInputElement, ... }

        if (value === '') {
            return true; // Let 'required' handle empty check
        }

        const vatPattern = /^[A-Z]{2}[0-9A-Z]{2,12}$/;
        if (!vatPattern.test(value.toUpperCase())) {
            return 'Please enter a valid VAT number (e.g. DE123456789).';
        }

        return true; // Valid
    }
);
</script>
<?php $hyvaCsp->registerInlineScript() ?>
```

### Return Value Rules

| Return | Meaning |
|--------|---------|
| `true` | Field is **valid** |
| `false` | Field is **invalid** — generic error shown |
| `'Error message string'` | Field is **invalid** — your message is displayed |

---

## Step 4 — Use the Rule in a Form with Alpine.js

```php
<?php
/** @var \Magento\Framework\Escaper $escaper */
/** @var \Hyva\Theme\ViewModel\HyvaCsp $hyvaCsp */
?>
<form x-data="hyva.formValidation($el)"
      @submit.prevent="onSubmit"
      novalidate>

    <div class="field field-reserved">
        <label for="vat_number"><?= $escaper->escapeHtml(__('VAT Number')) ?></label>
        <input type="text"
               id="vat_number"
               name="vat_number"
               data-validate='{"required": true, "validate-vat-number": true}'
               @change="onChange"
               class="form-input">
    </div>

    <button type="submit" class="btn btn-primary">
        <?= $escaper->escapeHtml(__('Submit')) ?>
    </button>
</form>
```

> **Important:** Wrap inputs in a `<div class="field field-reserved">` container so the validation message has reserved space to render without layout shift.

---

## Advanced Patterns

### Rule with Option Value

Use the `options` argument when the rule requires a configurable parameter:

```javascript
hyva.formValidation.addRule(
    'validate-promo-prefix',
    function (value, options, field) {
        // options = 'SALE' (from data-validate='{"validate-promo-prefix": "SALE"}')
        if (value && !value.startsWith(options)) {
            return hyva.str('Promo code must start with "%1".', options);
        }
        return true;
    }
);
```

```html
<input type="text"
       name="promo_code"
       data-validate='{"validate-promo-prefix": "SALE"}'
       @change="onChange">
```

### Accessing the Field Element

Use `field.element` to inspect the DOM input directly:

```javascript
hyva.formValidation.addRule(
    'validate-password-confirm',
    function (value, options, field) {
        const passwordField = field.element
            .closest('form')
            .querySelector('[name="password"]');

        if (passwordField && value !== passwordField.value) {
            return 'Passwords do not match.';
        }
        return true;
    }
);
```

### Async Validation Rule (Promise-based)

Return a `Promise` for server-side or async checks:

```javascript
hyva.formValidation.addRule(
    'validate-username-available',
    function (value, options, field) {
        if (!value) return true;

        return fetch('/rest/V1/check-username', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ username: value })
        })
        .then(response => response.json())
        .then(data => {
            if (!data.available) {
                return 'This username is already taken.';
            }
            return true;
        })
        .catch(() => true); // Fail open on network error
    }
);
```

### Combining with a Custom Alpine Component

When the form also has custom Alpine data, spread `hyva.formValidation` into your component:

```javascript
function initRegistrationForm() {
    return {
        ...hyva.formValidation(this.$el),
        username: '',
        setUsername() {
            this.username = this.$event.target.value;
        }
    };
}
window.addEventListener('alpine:init', () => Alpine.data('initRegistrationForm', initRegistrationForm), {once: true});
```

```html
<form x-data="initRegistrationForm" @submit.prevent="onSubmit" novalidate>
    <div class="field field-reserved">
        <input type="text"
               name="username"
               :value="username"
               @input="setUsername"
               @change="onChange"
               data-validate='{"required": true, "validate-username-available": true}'>
    </div>
    <button type="submit" class="btn btn-primary">Register</button>
</form>
```

---

## Complete Example: VAT Number Validation Module

### File Structure

```
app/code/Vendor/Module/
├── view/frontend/
│   ├── layout/
│   │   └── default.xml
│   └── templates/
│       └── validation/
│           └── validate-vat-number.phtml
```

### `default.xml`

```xml
<?xml version="1.0"?>
<page xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      xsi:noNamespaceSchemaLocation="urn:magento:framework:View/Layout/etc/page_configuration.xsd">
    <body>
        <referenceContainer name="before.body.end">
            <block name="validate-vat-number-rule"
                   template="Vendor_Module::validation/validate-vat-number.phtml"/>
        </referenceContainer>
    </body>
</page>
```

### `validate-vat-number.phtml`

```php
<?php
/** @var \Magento\Framework\View\Element\Template $block */
$hyvaCsp = $block->getData('hyvaCsp');
?>
<script>
hyva.formValidation.addRule(
    'validate-vat-number',
    function (value, options, field) {
        if (value === '') return true;

        const vatPattern = /^[A-Z]{2}[0-9A-Z]{2,12}$/;
        if (!vatPattern.test(value.toUpperCase())) {
            return 'Please enter a valid EU VAT number (e.g. DE123456789).';
        }
        return true;
    }
);
</script>
<?php $hyvaCsp->registerInlineScript() ?>
```

---

## Built-in Rules Reference

For reference, these rules ship with Hyvä and can be combined with your custom rules in `data-validate`:

| Rule | Example value | Description |
|------|--------------|-------------|
| `required` | `true` | Field must not be empty |
| `min` | `2` | Minimum numeric value |
| `max` | `100` | Maximum numeric value |
| `minlength` | `8` | Minimum string length |
| `maxlength` | `255` | Maximum string length |
| `email` | `true` | Valid email format |
| `url` | `true` | Valid URL format |
| `digits` | `true` | Digits only |
| `number` | `true` | Valid number |
| `equalTo` | `'#field-id'` | Must equal another field's value |

---

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Rule not found at validation time | Ensure rule PHTML loads **before** form template in page order |
| `options` is `true` instead of a value | Use `data-validate='{"rule-name": "actual-value"}'` |
| Forgetting `$hyvaCsp->registerInlineScript()` | Always call it after every `<script>` block |
| Rule script missing `hyva_form_validation` handle | Add `<update handle="hyva_form_validation"/>` to your layout |
| Not wrapping input in `.field.field-reserved` | Error messages won't render correctly |

---

## References

- Hyvä Form Validation Docs: https://docs.hyva.io/hyva-themes/writing-code/form-validation/javascript-form-validation.html
- Hyvä CSP Documentation: https://docs.hyva.io/hyva-themes/writing-code/csp/alpine-csp.html
- Alpine.js Documentation: https://alpinejs.dev/

<!-- Copyright © Hyvä Themes https://hyva.io. All rights reserved. Licensed under OSL 3.0 -->
