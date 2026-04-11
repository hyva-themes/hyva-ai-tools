---
name: hyva-add-tailwind-exclude
description: Add a module path to the `exclude` list in `hyva.config.json` for Tailwind configuration. Use this skill when the user wants to exclude a module from Tailwind CSS compilation. Trigger phrases include "exclude module", "add to exclude", "hyva-add-tailwind-exclude", or when a module path needs to be excluded from Tailwind.
---

# Add Module to Tailwind Exclude List

Adds a module path as a `{ "src": "<PATH>" }` entry to the `tailwind.exclude` array in `hyva.config.json`.

## Step 1: Find hyva.config.json

Delegate to the `hyva-theme-list` skill to find all Hyvä themes and their `hyva.config.json` locations.

- If only one theme is found, use it directly.
- If multiple themes are found, list them and ask the user which theme(s) to update. Wait for the answer before proceeding.

## Step 2: Resolve the Module Path

If a module name was provided by the user when invoking the skill, use it. Otherwise, prompt the user for the module path to exclude.

- If the argument contains `/` (e.g. `vendor/vendor-name/module-name`), use it as-is.
- If the argument is just a module name (e.g. `magento2-hyva-checkout`):
  1. Use the current working directory as the project root. Search for a directory matching the name under `vendor/` and `app/code/`.
  - If no match is found, inform the user and stop.
  - If exactly one match is found, derive its relative path from the project root (e.g. `vendor/hyva-themes/magento2-hyva-checkout`).
  - If multiple matches are found, list them and ask the user which one to use. Wait for the answer before proceeding.

## Step 3: Update Each Target File

For each target `hyva.config.json`:

1. Read the file.
2. Check if an entry with the resolved path already exists in `tailwind.exclude`. If it does, inform the user and skip that file.
3. Add `{ "src": "<PATH>" }` to the `tailwind.exclude` array.
4. Write the updated JSON back, preserving 2-space indentation and trailing newline.

## Step 4: Confirm

Report which file(s) were updated and what path was added.
