---
name: hyva-tailwind-include-exclude
description: Add a module path to the `include` or `exclude` list in `hyva.config.json` for Tailwind CSS compilation. Use this skill when the user wants to include a module in, or exclude a module from, Tailwind CSS compilation for a Hyvä theme. Trigger phrases include "include module", "exclude module", "add to include", "add to exclude", "hyva tailwind include", "hyva tailwind exclude".
requires: hyva-theme-list, hyva-compile-tailwind-css
---

# Add Module to Tailwind Include or Exclude List

Adds a module path as a `{ "src": "<PATH>" }` entry to either the `tailwind.include` or `tailwind.exclude` array in a theme's `hyva.config.json`. This is the Hyvä 1.4+ / Tailwind v4 mechanism; Step 3 handles older setups.

**Skill deps** (read via `<skill_path>/../{name}/SKILL.md`): `hyva-theme-list`, `hyva-compile-tailwind-css`

## Step 1: Determine the Target List

Decide whether the user wants to **include** or **exclude** the module in Tailwind CSS compilation:

- If the user's request clearly indicates one (e.g. "exclude", "include"), use it.
- Otherwise, ask the user whether to include or exclude the module. Wait for the answer before proceeding.

The chosen list is referred to as `<target>` (`include` or `exclude`) in the steps below.

## Step 2: Find the Theme(s)

Use the `hyva-theme-list` skill to find all Hyvä themes. For each theme, the config file is located at `<theme-path>/web/tailwind/hyva.config.json`.

- If no themes are found, inform the user and stop.
- If only one theme is found, use it directly.
- If multiple themes are found, list them and ask the user which theme(s) to update. Wait for the answer before proceeding.
- If a selected theme is located under `vendor/`, warn the user that changes to vendor files are lost on `composer update` and ask for confirmation before proceeding.

## Step 3: Confirm the Theme Uses Tailwind v4

`hyva.config.json` is only read by Hyvä 1.4+ / Tailwind v4 builds (via `hyva-sources`). Editing it on an older setup is a silent no-op. For each selected theme, read the `tailwindcss` version in `<theme-path>/web/tailwind/package.json`.

- If the major version is 4 or higher, continue to Step 4.
- If the major version is 3, the build does not read `hyva.config.json`; do not create or edit it. Instead tell the user how to make the change in the v3 setup, then stop for that theme:
  - To **exclude** a module, add its directory to `excludeDirs` in the `postcssImportHyvaModules(...)` call in `<theme-path>/web/tailwind/postcss.config.js`.
  - To **include** extra paths, add them to the `content` array in `<theme-path>/web/tailwind/tailwind.config.js`.

## Step 4: Resolve the Module Path

Use the current working directory as the project root. If a module name was provided by the user when invoking the skill, use it. Otherwise, prompt the user for the module to resolve.

### For an exclude

The exclude path must match the module's registered source path, which the build reads from `app/etc/hyva-themes.json` (a module can only be excluded if it is registered there). Modules register themselves for that file with the `hyva-register-module-tailwind` skill. Compatibility modules that use `CompatModuleRegistry` are registered automatically.

- Read `app/etc/hyva-themes.json` and find the entry for the module, matching by its `Vendor_Module` name or by the provided path or directory name.
- Use that entry's registered source path verbatim. It often ends in `/src` (e.g. `vendor/hyva-themes/magento2-hyva-checkout/src`).
- If the module is not listed there, it is not imported by the build and cannot be excluded. Inform the user and stop. If they intended the module to be compiled, register it first with the `hyva-register-module-tailwind` skill (skip that skill for compatibility modules that use `CompatModuleRegistry`; those are already registered automatically).

### For an include

Any directory relative to the project root can be included, so resolve it from the provided value:

- If the value contains `/` (e.g. `vendor/vendor-name/module-name`), verify the directory exists relative to the project root and use it as-is. If it does not exist, warn the user and ask how to proceed.
- If the value is a `Vendor_Module` name (e.g. `Hyva_Checkout`), look for `app/code/<Vendor>/<Module>` relative to the project root and use that path if it exists. If it is not found there, look it up under `vendor/` via its `registration.php`.
- Otherwise (a plain directory name, e.g. `magento2-hyva-checkout`), search for a directory matching the name under `vendor/` and `app/code/`:
  - If no match is found, inform the user and stop.
  - If exactly one match is found, derive its relative path from the project root (e.g. `vendor/hyva-themes/magento2-hyva-checkout`).
  - If multiple matches are found, list them and ask the user which one to use. Wait for the answer before proceeding.

## Step 5: Update Each Target File

For each target `hyva.config.json`:

1. Read the file. If it does not exist, create it with the structure `{ "tailwind": { "<target>": [] } }`. If the file exists but is not valid JSON, inform the user and stop without overwriting it.
2. Check if an entry with the resolved path already exists in `tailwind.<target>`. If it does, inform the user and skip that file. If the path exists in the opposite list (`tailwind.exclude` when including, or `tailwind.include` when excluding), warn the user and ask whether to remove it from there.
3. Add `{ "src": "<PATH>" }` to the `tailwind.<target>` array, where `<PATH>` is the resolved module path from Step 4. Create the `tailwind` key and the `<target>` array if they are missing. For example, excluding a module results in:
   ```json
   {
     "tailwind": {
       "exclude": [
         { "src": "vendor/hyva-themes/magento2-hyva-checkout/src" }
       ]
     }
   }
   ```
4. Write the updated JSON back, preserving the file's existing indentation and trailing newline.

## Step 6: Confirm

Report which file(s) were updated, which list (`include` or `exclude`) was changed, and what path was added.

## Step 7: Offer to Compile

The change has no visible effect until Tailwind CSS is recompiled. Offer to compile the Tailwind CSS for the updated theme(s) using the `hyva-compile-tailwind-css` skill so the change takes effect.

<!-- Copyright © Hyvä Themes https://hyva.io. All rights reserved. Licensed under OSL 3.0 -->
