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
| [hyva-render-media-image](skills/hyva-render-media-image/)     | Generate responsive `<picture>` elements using the Hyva Media view model                                                        |
| [hyva-theme-list](skills/hyva-theme-list/)                     | List all Hyva theme paths in a Magento 2 project                                                                                |
| [hyva-ui-component](skills/hyva-ui-component/)                 | Install Hyva UI template-based components (headers, footers, galleries, etc.) to themes                                         |

"Utility skills" are mainly intended to be invoked by other skills, but can of course also be used directly.

## Installation

Always install all skills together, as they often refer to each other.

### Quick Install

```bash
# For Claude Code
curl -fsSL https://raw.githubusercontent.com/hyva-themes/hyva-ai-tools/refs/heads/main/install.sh | sh -s claude

# For Codex
curl -fsSL https://raw.githubusercontent.com/hyva-themes/hyva-ai-tools/refs/heads/main/install.sh | sh -s codex

# For GitHub Copilot
curl -fsSL https://raw.githubusercontent.com/hyva-themes/hyva-ai-tools/refs/heads/main/install.sh | sh -s copilot

# For Cursor
curl -fsSL https://raw.githubusercontent.com/hyva-themes/hyva-ai-tools/refs/heads/main/install.sh | sh -s cursor

# For Gemini
curl -fsSL https://raw.githubusercontent.com/hyva-themes/hyva-ai-tools/refs/heads/main/install.sh | sh -s gemini

# For OpenCode
curl -fsSL https://raw.githubusercontent.com/hyva-themes/hyva-ai-tools/refs/heads/main/install.sh | sh -s opencode
```

### Manual Installation

1. Clone or download this repository
2. Copy the skill directories to your project:
    - **Claude Code**: `.claude/skills/`
    - **Codex**: `.codex/skills/`
    - **GitHub Copilot**: `.github/skills/`
    - **Cursor**: `.cursor/skills/`
    - **Gemini**: `.gemini/skills/`
    - **OpenCode**: `.opencode/skills/`

## Usage

Once installed, the AI assistant will automatically use these skills when relevant. You can also invoke them directly:

- "Create an Alpine component for a dropdown menu"
- "Create a Hyva child theme"
- "Add a CMS component for a hero banner"
- "Compile Tailwind CSS"
- "Apply the gallery component from Hyva UI"

## License

Licensed under the OSL-3.0.

---

Copyright (c) Hyva Themes https://hyva.io. All rights reserved.
