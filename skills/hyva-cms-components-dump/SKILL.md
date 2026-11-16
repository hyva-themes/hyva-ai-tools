---
name: hyva-cms-components-dump
description: Dump all Hyvä CMS components from active modules. This skill should be used when the user wants to list all CMS components, view available components, debug component configurations, or see the merged components.json output. Trigger phrases include "list cms components", "dump components", "show all components", "view cms components", "components.json dump".
requires: hyva-exec-shell-cmd
---

# Hyvä CMS Component Dump

Lists the Hyvä CMS components available in a Magento 2 project, merged across active
modules.

**Command execution:** Use the `hyva-exec-shell-cmd` skill to detect the environment
and determine the command wrapper. Run all commands below from the Magento project
root.

**Skill deps** (read via `<skill_path>/../{name}/SKILL.md`, where `<skill_path>` is the directory containing this SKILL.md file): `hyva-exec-shell-cmd`

## Step 1: Prefer the bin/magento CLI commands

Modern Hyvä CMS ships console commands that report the live, project-accurate set of
components (reflecting enabled state, plugins, and overrides). **Prefer these.**

Check availability once, then use what exists:

```bash
# via the detected wrapper, e.g. warden env exec -T php-fpm bash -c "bin/magento list hyva:cms"
bin/magento list hyva:cms
```

- `bin/magento hyva:cms:describe-components` — describe enabled CMS components
- `bin/magento hyva:cms:list-disabled-components` — list disabled CMS components

These run through the standard `bin/magento` wrapper (in the project's dev container);
no bundled script and no host PHP are involved.

## Step 2: Fallback — bundled dump script

If the `hyva:cms:*` commands are **not** available (older Hyvä CMS), fall back to the
bundled `scripts/dump_cms_components.php`. It `require`s `app/etc/config.php`, so it
needs a PHP interpreter — run it via the pattern documented in the
`hyva-exec-shell-cmd` skill ("Running a Bundled Skill Script Inside the
Environment"): stream the script into the interpreter over stdin, e.g.

```bash
# via the detected wrapper, working directory = project root
cat <skill_path>/scripts/dump_cms_components.php | warden env exec -T php-fpm bash -c "php /dev/stdin"
```

and capture stdout. The script locates the Magento root via `getcwd()`, so no temp
file, mount, or cleanup is involved.

**Output format:** A single JSON object containing all merged CMS component definitions.

### How the fallback script works

1. **Reads module configuration** from `app/etc/config.php` to get the ordered list of modules
2. **Filters active modules** - only modules with value `1` are included (disabled modules are skipped)
3. **Locates components.json files** in:
   - `app/code/{Vendor}/{Module}/etc/hyva_cms/components.json`
   - `vendor/{vendor-name}/{package-name}/*/etc/hyva_cms/components.json`
4. **Maps paths to module names** by reading each module's `etc/module.xml`
5. **Merges JSON objects** in module load order as declared in `config.php`
6. **Outputs the result** as formatted JSON

## Module Load Order

Components are merged in the exact order modules appear in `app/etc/config.php`. Later modules can override components from earlier modules by using the same component key.

## Example Output

```json
{
    "text_block": {
        "label": "Text Block",
        "category": "Content",
        "template": "Hyva_CmsBase::elements/text-block.phtml",
        ...
    },
    "feature_card": {
        "label": "Feature Card",
        "category": "Elements",
        "template": "Custom_Module::elements/feature-card.phtml",
        ...
    }
}
```

## Integration with Other Skills

This skill can be used to:
- Debug which components are available in the CMS editor
- Verify component registration after creating new components
- Check for component name conflicts between modules
- Export component definitions for documentation

<!-- Copyright © Hyvä Themes https://hyva.io. All rights reserved. Licensed under OSL 3.0 -->
