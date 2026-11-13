---
name: hyva-register-module-tailwind
description: Register a Magento 2 module for Hyvä Tailwind compilation so it is listed in app/etc/hyva-themes.json. Use when the user wants a module to ship Tailwind styles or config, add a hyva_config_generate_before observer, create view/frontend/tailwind files (module.css, tailwind.config.js, tailwind-source.css), or run hyva:config:generate. Trigger phrases include "register module for tailwind", "hyva-themes.json", "hyva_config_generate_before", "module tailwind compilation".
requires: hyva-exec-shell-cmd, hyva-compile-tailwind-css
---

# Register a Module for Tailwind Compilation

Adds a Magento 2 module to `app/etc/hyva-themes.json` so `@hyva-themes/hyva-modules` scans it for Tailwind configuration and CSS during compilation. This is done from the module itself, with an observer on `hyva_config_generate_before`. Do not confuse this with the `hyva-tailwind-include-exclude` skill, which edits a theme's `hyva.config.json` include/exclude lists.

Follow the official documentation exactly; do not invent APIs or event names:

- [Registering a Module for Tailwind Compilation](https://docs.hyva.io/hyva-themes/working-with-tailwindcss/registering-a-module-for-tailwind-compilation.html)
- [Tailwind Asset Merging](https://docs.hyva.io/hyva-themes/compatibility-modules/technical-deep-dive.html) (module Tailwind files)
- [hyva-sources](https://docs.hyva.io/hyva-themes/working-with-tailwindcss/using-hyva-modules/sources.html) (Tailwind v4)

**Command execution:** For commands that need to run inside the development environment (e.g., `bin/magento`), use the `hyva-exec-shell-cmd` skill to detect the environment and determine the appropriate command wrapper.

**Skill deps** (read via `<skill_path>/../{name}/SKILL.md`): `hyva-exec-shell-cmd`, `hyva-compile-tailwind-css`

## Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `vendor` | Yes | Vendor name in PascalCase (e.g., `My`) |
| `module` | Yes | Module name in PascalCase (e.g., `Module`) |
| `module_path` | No | Filesystem path to the module, relative to the Magento root if known (e.g., `app/code/My/Module` or `vendor/acme/module-anvil/src`). Resolved in Step 1 if omitted. |

The Magento module name is `{Vendor}_{Module}` (e.g., `My_Module`). The PHP namespace is `{Vendor}\{Module}`.

## Step 1: Identify the Module

Resolve `{Vendor}`, `{Module}`, and the module directory:

- If a `Vendor_Module` name was provided, look for `app/code/{Vendor}/{Module}` first, then locate it under `vendor/` via `registration.php`.
- If a path was provided, verify it exists and read the module name from `etc/module.xml` or `registration.php`.
- If neither is clear, ask the user which module to register. Wait for the answer before proceeding.

**Compatibility modules are registered automatically.** If the module registers itself with `Hyva\CompatModuleFallback\Model\CompatModuleRegistry` in `etc/frontend/di.xml` (automatic template overrides), do not add this observer. Inform the user that compatibility modules using `CompatModuleRegistry` are already included in `hyva-themes.json`, and stop.

If `etc/frontend/events.xml` already declares an observer on `hyva_config_generate_before` that registers this module, say so and continue from Step 4 (Tailwind files) if those still need to be added.

## Step 2: Declare the Event Observer

Register an observer for `hyva_config_generate_before` in the module's `etc/frontend/events.xml`.

If `etc/frontend/events.xml` does not exist, create it from `assets/templates/events.xml.tpl`. If it already exists, merge the observer into the existing `<config>` — do not overwrite other observers.

Replacements:

- `{{VENDOR}}` — PascalCase vendor name
- `{{MODULE}}` — PascalCase module name

The observer `name` must be `{Vendor}_{Module}_Register_Hyva_Config`. The `instance` must be `{Vendor}\{Module}\Observer\RegisterModuleForHyvaConfig`.

Official shape (substitute the module name):

```xml
<config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="urn:magento:framework:Event/etc/events.xsd"
>
    <event name="hyva_config_generate_before">
        <observer
            name="My_Module_Register_Hyva_Config"
            instance="My\Module\Observer\RegisterModuleForHyvaConfig"
        />
    </event>
</config>
```

## Step 3: Implement the Observer

Create `Observer/RegisterModuleForHyvaConfig.php` from `assets/templates/RegisterModuleForHyvaConfig.php.tpl`.

Replacements: `{{VENDOR}}`, `{{MODULE}}`, and `{{VENDOR_MODULE}}` (`Vendor_Module`, e.g., `My_Module`).

The observer receives the configuration object that is written to `app/etc/hyva-themes.json`. It must append the module path **relative to the Magento root** to the `extensions[].src` array. Resolve the absolute path with `ComponentRegistrar` and strip the Magento base dir (`BP`) as in the official example. Do not hard-code `app/code/...` or `vendor/...`.

Official shape (substitute the module name):

```php
<?php

declare(strict_types=1);

namespace My\Module\Observer;

use Magento\Framework\Component\ComponentRegistrar;
use Magento\Framework\Event\Observer;
use Magento\Framework\Event\ObserverInterface;

class RegisterModuleForHyvaConfig implements ObserverInterface
{
    private ComponentRegistrar $componentRegistrar;

    public function __construct(ComponentRegistrar $componentRegistrar)
    {
        $this->componentRegistrar = $componentRegistrar;
    }

    public function execute(Observer $event)
    {
        $config = $event->getData('config');
        $extensions = $config->hasData('extensions') ? $config->getData('extensions') : [];

        // Resolve the full filesystem path for this module
        $path = $this->componentRegistrar->getPath(ComponentRegistrar::MODULE, 'My_Module');

        // Only use the path relative to the Magento base dir
        $extensions[] = ['src' => substr($path, strlen(BP) + 1)];

        $config->setData('extensions', $extensions);
    }
}
```

A generated `hyva-themes.json` looks like this (paths vary; `vendor/...` entries often end in `/src`):

```json
{
    "extensions": [
        {
            "src": "app/code/My/Module"
        },
        {
            "src": "vendor/Acme/Anvil/src"
        }
    ]
}
```

## Step 4: Add Module Tailwind Files

Registration only tells the build to scan the module. The module must also ship Tailwind sources in `view/frontend/tailwind/` (or `view/adminhtml/tailwind/` if the theme area is adminhtml). Do not invent filenames or APIs beyond those documented below.

If the files already exist and are intentional, leave them in place. Do not add leftover legacy files when creating a new `module.css` setup, and do not add `module.css` on top of a maintained legacy setup unless the user asks to migrate.

### Recommended for new work and Tailwind v4: `module.css`

For full Tailwind v4 compatibility, provide a single `view/frontend/tailwind/module.css`. When this file is present, the build treats it as the single source of truth and **ignores** `tailwind.config.js` and `tailwind-source.css` in the same directory.

The file should contain:

1. `@source` directives for the files Tailwind should scan for class names.
2. `@import` statements for additional CSS files in the module, only when those files exist.

Use `assets/templates/module.css.tpl` as the starting point. Official example:

```css
/* Example: view/frontend/tailwind/module.css */

/* 1. Add module templates to the content scan */
@source "../templates";
@source "../layout";

/* 2. Import module-specific CSS files */
@import "./components/widget.css";
```

Omit any `@import` whose target file does not exist. Keep `@source` paths that match directories the module actually has (typically `view/frontend/templates` and `view/frontend/layout`).

If themes in the project can be identified, use the `tailwindcss` major version in `<theme-path>/web/tailwind/package.json` (as in `hyva-tailwind-include-exclude`) to choose the approach: major version 4 or higher → `module.css`; major version 3 → legacy files below. If the version is unknown, prefer `module.css` for new work and mention the legacy method for Tailwind v3 themes.

### Legacy fallback: `tailwind.config.js` and `tailwind-source.css`

If `module.css` is not present, the build looks for `tailwind.config.js` and `tailwind-source.css`. Behavior depends on the theme's Tailwind version:

**Tailwind v3 theme:**

- `tailwind.config.js`: the `purge.content` paths from this file are merged with the theme's configuration.
- `tailwind-source.css`: `@import` statements from this file are added to the theme's CSS build.

**Tailwind v4 theme:**

- `tailwind.config.js`: if this file exists, the build adds a generic `@source` directive to scan all `.phtml` and `.xml` files within the module. It does not deep-merge the config file. For `hyva-sources`, that generic scan is generated only when `tailwind.config.js` is present (unless `module.css` is used instead).
- `tailwind-source.css`: `@import` statements are added to the build. Paths inside the file must be explicit relative paths (e.g. `@import "./components/widget.css";`).

The legacy method exists for backward compatibility. Prefer `module.css` for all new development.

## Step 5: Generate `hyva-themes.json`

The module must be enabled before generation will pick up the observer. If it was just created or was disabled, run `bin/magento module:enable {Vendor}_{Module}` and `bin/magento setup:upgrade` first, using `hyva-exec-shell-cmd`.

Then generate the file:

```bash
bin/magento hyva:config:generate
```

This command writes `app/etc/hyva-themes.json`. Most commands that modify `app/etc/config.php` also regenerate it.

## Step 6: Verify

Read `app/etc/hyva-themes.json` and confirm an `extensions[].src` entry matches this module's path relative to the Magento root (the same path `ComponentRegistrar` would produce after stripping `BP`).

If the entry is missing:

- Confirm the module is enabled (`bin/magento module:status {Vendor}_{Module}`).
- Confirm `etc/frontend/events.xml` is in the frontend area and the observer class name matches the `instance` attribute.
- Report the failure; do not hand-edit `hyva-themes.json` as a substitute for a working observer (the file is generated).

## Step 7: Offer to Recompile

Registration and Tailwind source files have no visible effect until theme CSS is rebuilt. Offer to compile Tailwind CSS for the relevant Hyvä theme(s) using the `hyva-compile-tailwind-css` skill. On Tailwind v4 themes, that build uses `hyva-sources`, which reads `app/etc/hyva-themes.json`.

## Error Handling

| Condition | Action |
|-----------|--------|
| Module cannot be resolved | Ask the user for the `Vendor_Module` name or path; do not guess |
| Compatibility module via `CompatModuleRegistry` | Stop; it is already registered automatically |
| Observer or events.xml already registers this module | Leave them in place; continue from Tailwind files if needed |
| Cannot write a file | Report: "Failed to write {filename}: {error}" |
| Module not enabled | Enable it (with user confirmation if that would change production-like config) before `hyva:config:generate` |
| `hyva:config:generate` fails or omits the module | Report the command output and the checks in Step 6; do not invent a workaround API |
| `hyva-exec-shell-cmd` unavailable | Report: "hyva-exec-shell-cmd skill not available. Run manually: bin/magento hyva:config:generate" |

<!-- Copyright © Hyvä Themes https://hyva.io. All rights reserved. Licensed under OSL 3.0 -->
