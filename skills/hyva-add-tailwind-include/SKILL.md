---
name: hyva-add-tailwind-include
description: Add a module path to the `include` list in `hyva.config.json` for Tailwind configuration. Use this skill when the user wants to include a module in Tailwind CSS compilation. Trigger phrases include "include module", "add to include", "hyva-add-tailwind-include", or when a module path needs to be included in Tailwind.
---

# Add Module to Tailwind Include List

Adds a module path as a `{ "src": "<PATH>" }` entry to the `tailwind.include` array in `hyva.config.json`.

## Step 1: Find hyva.config.json

Use the Glob tool with pattern `**/hyva.config.json` to find all config files.

- If only one file is found, use it directly.
- If multiple files are found, list them and ask the user which theme(s) to update. Wait for the answer before proceeding.

## Step 2: Resolve the Module Path

The module path comes from the skill argument (`$ARGUMENTS`).

- If the argument contains `/` (e.g. `vendor/vendor-name/module-name`), use it as-is.
- If the argument is just a module name (e.g. `magento2-hyva-checkout`):
  1. Use Bash: `find <project-root> -type d -name "MODULE_NAME"`.
  - If no match is found, inform the user and stop.
  - If exactly one match is found, derive its relative path from the project root (e.g. `vendor/hyva-themes/magento2-hyva-checkout`).
  - If multiple matches are found, list them and ask the user which one to use. Wait for the answer before proceeding.

## Step 3: Update Each Target File

For each target `hyva.config.json`:

1. Read the file.
2. Check if an entry with the resolved path already exists in `tailwind.include`. If it does, inform the user and skip that file.
3. Add `{ "src": "<PATH>" }` to the `tailwind.include` array.
4. Write the updated JSON back, preserving 2-space indentation.

## Step 4: Confirm

Report which file(s) were updated and what path was added.
