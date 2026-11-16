---
name: hyva-register-module-tailwind
description: Register a Magento 2 module for Hyvä Tailwind compilation so it is listed in app/etc/hyva-themes.json. Use when the user wants a module to ship Tailwind styles or config, add a hyva_config_generate_before observer, create view/frontend/tailwind files (module.css, tailwind.config.js, tailwind-source.css), or run hyva:config:generate. Trigger phrases include "register module for tailwind", "hyva-themes.json", "hyva_config_generate_before", "module tailwind compilation".
requires: hyva-exec-shell-cmd, hyva-compile-tailwind-css
---

# Register a Module for Tailwind Compilation

Adds a Magento 2 module to `app/etc/hyva-themes.json` so `@hyva-themes/hyva-modules` scans it for Tailwind configuration and CSS during compilation. This is done from the module itself, with an observer on `hyva_config_generate_before`. This is a different task from adding a module to the include/exclude lists in a theme's `hyva.config.json`.

Follow the official documentation exactly; do not invent APIs, event names or file names:

- [Registering a Module for Tailwind Compilation](https://docs.hyva.io/hyva-themes/working-with-tailwindcss/registering-a-module-for-tailwind-compilation.html)
- [Tailwind Asset Merging](https://docs.hyva.io/hyva-themes/compatibility-modules/technical-deep-dive.html) (module Tailwind files)
- [hyva-sources](https://docs.hyva.io/hyva-themes/working-with-tailwindcss/using-hyva-modules/sources.html) (Tailwind v4)

**Command execution:** For commands that need to run inside the development environment (e.g., `bin/magento`), use the `hyva-exec-shell-cmd` skill to detect the environment and determine the appropriate command wrapper.

**Skill deps** (read via `<skill_path>/../{name}/SKILL.md`, where `<skill_path>` is the directory containing this SKILL.md file): `hyva-exec-shell-cmd`, `hyva-compile-tailwind-css`

**Non-interactive runs:** Where a step says to ask the user and the user cannot be asked (subagent or non-interactive run), stop and report which input or confirmation is missing, unless the step itself says what to do in that case. Do not guess the module, do not write into a package under `vendor/` that is not a symlink without confirmation, and do not compile Tailwind CSS; state in the final report that the styles need recompiling.

## Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `vendor` | Yes, unless `module_path` is given | Vendor name in PascalCase (e.g., `My`) |
| `module` | Yes, unless `module_path` is given | Module name in PascalCase (e.g., `Module`) |
| `module_path` | No | Filesystem path to the module, relative to the Magento root if known (e.g., `app/code/My/Module` or `vendor/acme/module-anvil/src`). Resolved in Step 1 if omitted. |

The Magento module name is `{Vendor}_{Module}` (e.g., `My_Module`). The PHP namespace is `{Vendor}\{Module}`.

## Step 1: Identify the Module

Resolve `{Vendor}`, `{Module}`, and the module directory:

- If a `Vendor_Module` name was provided, look for `app/code/{Vendor}/{Module}` first, then locate it under `vendor/` via `registration.php`.
- If a path was provided, verify it exists and read the module name from `etc/module.xml` or `registration.php`.
- If neither is clear, ask the user which module to register. Wait for the answer before proceeding.

**Compatibility modules are registered automatically.** If the module registers itself with `Hyva\CompatModuleFallback\Model\CompatModuleRegistry` in `etc/frontend/di.xml` (automatic template overrides), do not add this observer. Inform the user that compatibility modules using `CompatModuleRegistry` are already included in `hyva-themes.json`, and stop.

**Already registered.** If `etc/frontend/events.xml` already declares an observer on `hyva_config_generate_before` that registers this module, say so and skip Steps 2 and 3. Continue with Step 4 if the Tailwind files still need to be added, otherwise with Step 5.

**Modules under `vendor/`.** If files still need to be written and the module directory is inside `vendor/`, check whether the package directory is a symlink.

- Not a symlink: warn the user that files written there are overwritten when Composer reinstalls or updates the package, and that the change belongs in the package's source repository. Ask for confirmation before writing anything.
- A symlink: this usually means a local path repository that the user develops, so no confirmation is needed. Resolve the real path of the link target. If it lies outside the Magento root, stop before writing anything and report that the observer from the documentation cannot register this module, because it needs a path relative to the Magento root.

## Step 2: Declare the Event Observer

Register an observer for `hyva_config_generate_before` in the module's `etc/frontend/events.xml`.

If `etc/frontend/events.xml` does not exist, create it from `assets/templates/events.xml.tpl`. If it already exists, add the `<event>` element from the template to the existing `<config>`. If the file already has an `<event name="hyva_config_generate_before">`, add only the `<observer>` to that element: the schema allows each event name once per file. Do not overwrite other observers.

Replacements:

- `{{VENDOR}}`: PascalCase vendor name
- `{{MODULE}}`: PascalCase module name

The result must have the observer `name` `{Vendor}_{Module}_Register_Hyva_Config` and the `instance` `{Vendor}\{Module}\Observer\RegisterModuleForHyvaConfig`. The template is the example from the official documentation; do not change its structure.

## Step 3: Implement the Observer

Create `Observer/RegisterModuleForHyvaConfig.php` from `assets/templates/RegisterModuleForHyvaConfig.php.tpl`.

Replacements: `{{VENDOR}}`, `{{MODULE}}`, and `{{VENDOR_MODULE}}` (`Vendor_Module`, e.g., `My_Module`).

The template is the observer from the official documentation. It receives the configuration object that is written to `app/etc/hyva-themes.json` and appends the module path **relative to the Magento root** to the `extensions[].src` array. It resolves the absolute path with `ComponentRegistrar` and strips the Magento base dir (`BP`). Do not replace this with a hard-coded `app/code/...` or `vendor/...` path.

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

Registration only tells the build to scan the module. The module must also ship Tailwind sources in `view/frontend/tailwind/`. For an admin theme on Tailwind v4 (`tailwind.area` set to `adminhtml` in the theme's `hyva.config.json`), `hyva-sources` reads the module's `module.css` or `tailwind-source.css` from `view/adminhtml/tailwind/` instead; create the files there when the module targets such a theme. Do not invent filenames or APIs beyond those documented below.

If the files already exist and are intentional, leave them in place. Do not add legacy files next to a new `module.css` unless the project has Tailwind v3 themes (see below), and do not add `module.css` on top of a maintained legacy setup unless the user asks to migrate.

### Choose the approach

Read the `tailwindcss` major version in `<theme-path>/web/tailwind/package.json` of the project's Hyvä themes. Use the themes in `app/design/frontend/`; if there are none, use the Hyvä themes under `vendor/`.

- All themes on version 4 or higher: use `module.css`.
- All themes on version 3: use the legacy files. A Tailwind v3 build reads only `tailwind.config.js` and `tailwind-source.css`, so `module.css` alone has no effect there.
- Themes on both versions: create `module.css` for the v4 themes and the legacy files for the v3 themes. A v4 build ignores the legacy files when `module.css` is present, so the two do not conflict. If the module already has working legacy files, leave it as it is: a v4 build uses the legacy files when there is no `module.css`.
- No theme found or version unknown: use `module.css` and mention the legacy method for Tailwind v3 themes.

### Recommended for new work and Tailwind v4: `module.css`

For full Tailwind v4 compatibility, provide a single `view/frontend/tailwind/module.css`. When this file is present, the build treats it as the single source of truth and **ignores** `tailwind.config.js` and `tailwind-source.css` in the same directory.

The file should contain:

1. `@source` directives for the files Tailwind should scan for class names.
2. `@import` statements for additional CSS files in the module, only when those files exist.

Create it from `assets/templates/module.css.tpl`, which follows the example in the official documentation. Then adjust it to the module:

- Keep `@source "../templates";` in any case, so that templates added later are scanned. Remove `@source "../layout";` if the module has no `view/frontend/layout` directory.
- Add an `@import "./<path>.css";` line for each CSS file the module ships in `view/frontend/tailwind/`, other than `module.css` and `tailwind-source.css`. Leave out the commented example if there are none.

### Legacy fallback: `tailwind.config.js` and `tailwind-source.css`

If `module.css` is not present, the build looks for `tailwind.config.js` and `tailwind-source.css`. Behavior depends on the theme's Tailwind version:

**Tailwind v3 theme:**

- `tailwind.config.js`: the `purge.content` paths from this file are merged with the theme's configuration.
- `tailwind-source.css`: `@import` statements from this file are added to the theme's CSS build.

**Tailwind v4 theme:**

- `tailwind.config.js`: if this file exists, the build adds a generic `@source` directive to scan all `.phtml` and `.xml` files within the module. It does not deep-merge the config file.
- `tailwind-source.css`: `@import` statements are added to the build. Paths inside the file must be explicit relative paths (e.g. `@import "./components/widget.css";`).

The legacy method exists for backward compatibility. Prefer `module.css` for all new development.

The official documentation gives no example contents for the legacy files, and this skill ships no template for them. When they are needed, use modules in this project that are already listed in `app/etc/hyva-themes.json` as a reference, and treat the two files separately:

- `tailwind.config.js`: copy the structure of the `content` paths from a registered module that has this file in `view/frontend/tailwind/`. The Hyvä theme module (`Hyva_Theme`) normally has one. Do not copy theme extensions, safelists or other settings, and adjust the paths to this module. The paths are relative to `view/frontend/tailwind/`.
- `tailwind-source.css`: create it only if the module has CSS files to import. Copy the form of the `@import` lines from a registered module that has this file.

If no registered module has the file that is needed, do not make up its contents and do not create it. Continue with Steps 5 and 6 so that the module is registered, and state in the final report which legacy file is missing and that example contents are needed.

## Step 5: Generate `hyva-themes.json`

Magento must know about the module and its new observer before generation picks it up. Check the module's entry in `app/etc/config.php`, or run `bin/magento module:status {Vendor}_{Module}`:

- Enabled (`1` in `config.php`): the event configuration is cached. Run `bin/magento cache:clean config compiled_config`. Magento 2.4.8 and later keep the event configuration in the `compiled_config` cache type, earlier versions in `config`.
- Not listed in `config.php` (a new module that was never installed): run `bin/magento setup:upgrade`, which installs and enables it.
- Disabled (`0` in `config.php`): ask before enabling it. If the user agrees, run `bin/magento module:enable {Vendor}_{Module}` and `bin/magento setup:upgrade`. If the user declines or cannot be asked, stop and report that the module has to be enabled first.

Do not run `bin/magento setup:di:compile` yourself. In production mode (`bin/magento deploy:mode:show`):

- If `setup:upgrade` was run, state in the final report that `setup:di:compile` has to be run, because `setup:upgrade` removes the generated code.
- If generation fails with a class or dependency injection error for the observer, report that `setup:di:compile` is needed, and `composer dump-autoload` if Composer's classmap is authoritative.

Then generate the file:

```bash
bin/magento hyva:config:generate
```

This command writes `app/etc/hyva-themes.json`. Most commands that modify `app/etc/config.php` also regenerate it.

## Step 6: Verify

Read `app/etc/hyva-themes.json` and confirm an `extensions[].src` entry matches this module's path relative to the Magento root (the same path `ComponentRegistrar` would produce after stripping `BP`).

For a symlinked package the entry is the path of the link target, not `vendor/...`, because PHP resolves the symlink. If the target lies outside the Magento root, the observer cannot produce a valid relative path: report this instead of treating the entry as correct.

If the entry is missing:

- Confirm the module is enabled (`bin/magento module:status {Vendor}_{Module}`).
- Run `bin/magento cache:clean config compiled_config`, then generate again.
- Confirm `etc/frontend/events.xml` is in the frontend area and the observer class name matches the `instance` attribute.
- Report the failure; do not hand-edit `hyva-themes.json` as a substitute for a working observer (the file is generated).

## Step 7: Offer to Recompile

Registration and Tailwind source files have no visible effect until theme CSS is rebuilt. Offer to compile Tailwind CSS for the relevant Hyvä theme(s) using the `hyva-compile-tailwind-css` skill. On Tailwind v4 themes, that build uses `hyva-sources`, which reads `app/etc/hyva-themes.json`.

## Error Handling

| Condition | Action |
|-----------|--------|
| Module cannot be resolved | Ask the user for the `Vendor_Module` name or path; do not guess |
| Compatibility module via `CompatModuleRegistry` | Stop; it is already registered automatically |
| Module is inside `vendor/` and not a symlinked package | Warn that the files are overwritten when Composer reinstalls or updates the package, and ask for confirmation |
| Symlinked package whose real path is outside the Magento root | Stop before writing; report that the observer cannot register it |
| Observer or events.xml already registers this module | Leave them in place; continue from Tailwind files if needed |
| Cannot write a file | Report: "Failed to write {filename}: {error}" |
| Module not enabled | Follow Step 5: `setup:upgrade` for a module that was never installed; ask before enabling a disabled one |
| Legacy Tailwind file needed and no registered module has one to use as a reference | Do not create it; finish Steps 5 and 6 and report which file is missing |
| `hyva:config:generate` fails or omits the module | Report the command output and the checks in Step 6; do not invent a workaround API |
| `hyva-exec-shell-cmd` unavailable | Report: "hyva-exec-shell-cmd skill not available. Run manually: bin/magento cache:clean config compiled_config && bin/magento hyva:config:generate" |

<!-- Copyright © Hyvä Themes https://hyva.io. All rights reserved. Licensed under OSL 3.0 -->
