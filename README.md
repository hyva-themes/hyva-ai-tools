# Hyva AI Skills

AI-powered skills for Magento 2 development with Hyva Theme. These skills extend AI coding assistants with specialized
knowledge for creating Hyva themes, modules, and CMS components.

## Available Skills

| Skill                                                          | Description                                                                                                                     |
|----------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------|
| [hyva-alpine-component](skills/hyva-alpine-component/)         | Write CSP-compatible Alpine.js components for Hyvä themes following best practices                                               |
| [hyva-child-theme](skills/hyva-child-theme/)                   | Create a Hyva child theme with proper directory structure, Tailwind CSS configuration, and theme inheritance                    |
| [hyva-cms-component](skills/hyva-cms-component/)               | Create custom Hyva CMS components with field presets, variant support, and PHTML templates                                      |
| [hyva-cms-components-dump](skills/hyva-cms-components-dump/)   | Dump combined JSON of all available Hyvä CMS components from active modules                                                     |
| [hyva-cms-custom-field](skills/hyva-cms-custom-field/)         | Create custom field types and field handlers for Hyvä CMS components                                                            |
| [hyva-compile-tailwind-css](skills/hyva-compile-tailwind-css/) | Utility skill to compile Tailwind CSS for Hyva themes                                                                           |
| [hyva-create-module](skills/hyva-create-module/)               | Scaffold new Magento 2 modules in app/code/                                                                                     |
| [hyva-exec-shell-cmd](skills/hyva-exec-shell-cmd/)             | Utility skill to detect development environment (Warden, docker-magento, local) and execute commands with appropriate wrappers  |
| [hyva-playwright-test](skills/hyva-playwright-test/)           | Write Playwright tests for Hyvä themes with Alpine.js                                                                           |
| [hyva-render-media-image](skills/hyva-render-media-image/)     | Generate responsive `<picture>` elements using the Hyva Media view model                                                        |
| [hyva-theme-list](skills/hyva-theme-list/)                     | List all Hyva theme paths in a Magento 2 project                                                                                |
| [hyva-ui-component](skills/hyva-ui-component/)                 | Install Hyva UI template-based components (headers, footers, galleries, etc.) to themes                                         |

"Utility skills" are mainly intended to be invoked by other skills, but can of course also be used directly.

## Installation

### Install Individual Skills (Recommended)

Clone this repository, then use `install-hyva-skill.sh` to install individual skills by name.
Dependencies are resolved automatically.

```bash
git clone https://github.com/hyva-themes/hyva-ai-tools.git

# Install a skill for a specific agent (from your project directory)
./hyva-ai-tool/sinstall-hyva-skill.sh hyva-child-theme claude

# Or let the installer auto-detect the agent directory
./hyva-ai-tool/sinstall-hyva-skill.sh hyva-cms-component

# List all available skills
./hyva-ai-tools/install-hyva-skill.sh --list
```

Skills are symlinked into the target agent's skills directory.
To update all installed skills, simply run `git pull` inside the cloned repository — every symlinked skill picks up the changes immediately.

Use `--copy` to copy skills instead of symlinking (e.g. when the repo is on the host but the agent runs in a container):

```bash
./hyva-ai-tools/install-hyva-skill.sh --copy hyva-child-theme claude
```

Copied skills won't update automatically with `git pull` — re-run the install command to update them.

When no agent argument is given, the installer will:
1. Use the `HYVA_SKILLS_AGENT` environment variable if set
2. Auto-detect an existing agent directory (e.g. `.claude/skills/`) in the current working directory
3. Prompt you to choose an agent and whether to install globally (`~/`) or locally (`./`)

Supported agents: `claude`, `codex`, `copilot`, `cursor`, `gemini`, `junie`, `opencode`

### Install All Skills at Once (Legacy)

To install all skills in one go (copies instead of symlinks):

```bash
# Replace "claude" with your agent: codex, copilot, cursor, gemini, junie, opencode
curl -fsSL https://raw.githubusercontent.com/hyva-themes/hyva-ai-tools/refs/heads/main/install.sh | sh -s claude
```

## Usage

Once installed, the AI agent will automatically use these skills when relevant. You can also invoke them directly:

- "Create an Alpine component for a dropdown menu"
- "Create a Hyva child theme"
- "Add a CMS component for a hero banner"
- "Compile Tailwind CSS"
- "Apply the gallery component from Hyva UI"

## License

Licensed under the OSL-3.0.

---

Copyright (c) Hyva Themes https://hyva.io. All rights reserved.
