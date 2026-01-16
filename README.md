# Hyva AI Skills

AI-powered skills for Magento 2 development with Hyva Theme. These skills extend AI coding assistants with specialized knowledge for creating Hyva themes, modules, and CMS components.

## Available Skills

| Skill | Description |
|-------|-------------|
| [hyva-child-theme](skills/hyva-child-theme/) | Create a Hyva child theme with proper directory structure, Tailwind CSS configuration, and theme inheritance |
| [hyva-cms-component](skills/hyva-cms-component/) | Create custom Hyva CMS components with field presets, variant support, and PHTML templates |
| [hyva-compile-tailwind-css](skills/hyva-compile-tailwind-css/) | Utility skill to compile Tailwind CSS for Hyva themes |
| [hyva-create-module](skills/hyva-create-module/) | Scaffold new Magento 2 modules in app/code/ |
| [hyva-exec-shell-cmd](skills/hyva-exec-shell-cmd/) | Utility skill to detect development environment (Warden, docker-magento, local) and execute commands with appropriate wrappers |
| [hyva-render-media-image](skills/hyva-render-media-image/) | Generate responsive `<picture>` elements using the Hyva Media view model |
| [hyva-theme-list](skills/hyva-theme-list/) | List all Hyva theme paths in a Magento 2 project |
| [hyva-ui-component](skills/hyva-ui-component/) | Install Hyva UI template-based components (headers, footers, galleries, etc.) to themes |

"Utility skills" are mainly intended to be invoked by other skills, but can of course also be used directly.

## Installation

### Quick Install

```bash
# For Claude Code
curl -fsSL https://gitlab.hyva.io/hyva-internal/hyva-ai-tools/-/raw/main/install.sh | sh -s claude

# For Gemini
curl -fsSL https://gitlab.hyva.io/hyva-internal/hyva-ai-tools/-/raw/main/install.sh | sh -s gemini
```

### Manual Installation

1. Clone or download this repository
2. Copy the skill directories to your project:
   - **Claude Code**: `.claude/skills/`
   - **Gemini**: `.gemini/skills/`

## Usage

Once installed, the AI assistant will automatically use these skills when relevant. You can also invoke them directly:

- "Create a Hyva child theme"
- "Add a CMS component for a hero banner"
- "Compile Tailwind CSS"
- "Apply the gallery component from Hyva UI"

## License

Licensed under the OSL-3.0.

---

Copyright (c) Hyva Themes https://hyva.io. All rights reserved.
