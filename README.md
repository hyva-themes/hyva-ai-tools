# Hyva AI Skills

AI-powered skills for Magento 2 development with Hyva Theme.
These skills extend AI coding assistants with specialized knowledge for creating Hyva themes,
modules, and CMS components.

## Installation

> [!NOTE]
> Always install all skills together, as they often refer to each other.

### Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/hyva-themes/hyva-ai-tools/refs/heads/main/install.sh | sh -s claude
```

Replace `claude` with your AI assistant: `codex` · `copilot` · `cursor` · `gemini` · `opencode`

### Manual Installation

1. Clone or download this repository
2. Copy the `skills/` directory to your project under the appropriate path:

| AI Assistant | Install Path |
|---|---|
| Claude Code | `.claude/skills/` |
| Codex | `.codex/skills/` |
| GitHub Copilot | `.github/skills/` |
| Cursor | `.cursor/skills/` |
| Gemini | `.gemini/skills/` |
| OpenCode | `.opencode/skills/` |

## Usage

Once installed, the AI assistant will automatically use these skills when relevant. You can also invoke them directly:

- "Create an Alpine component for a dropdown menu"
- "Create a Hyva child theme"
- "Add a CMS component for a hero banner"
- "Compile Tailwind CSS"
- "Apply the gallery component from Hyva UI"
- `/hyva-child-theme` (explicit slash command invocation)

## Available Skills

### Theme & Module Development

| Skill | Description |
|-------|-------------|
| [hyva-child-theme](skills/hyva-child-theme/) | Create a Hyva child theme with proper directory structure, Tailwind CSS configuration, and theme inheritance |
| [hyva-create-module](skills/hyva-create-module/) | Scaffold new Magento 2 modules in `app/code/` |
| [hyva-alpine-component](skills/hyva-alpine-component/) | Write CSP-compatible Alpine.js components for Hyvä themes following best practices |
| [hyva-ui-component](skills/hyva-ui-component/) | Install Hyva UI template-based components (headers, footers, galleries, etc.) to themes |
| [hyva-render-media-image](skills/hyva-render-media-image/) | Generate responsive `<picture>` elements using the Hyva Media view model |
| [hyva-playwright-test](skills/hyva-playwright-test/) | Write Playwright tests for Hyvä themes with Alpine.js |

### CMS Components

| Skill | Description |
|-------|-------------|
| [hyva-cms-component](skills/hyva-cms-component/) | Create custom Hyva CMS components with field presets, variant support, and PHTML templates |
| [hyva-cms-custom-field](skills/hyva-cms-custom-field/) | Create custom field types and field handlers for Hyvä CMS components |
| [hyva-cms-components-dump](skills/hyva-cms-components-dump/) | Dump combined JSON of all available Hyvä CMS components from active modules |

### Utility Skills

> Utility skills are mainly intended to be invoked by other skills, but can also be used directly.

| Skill | Description |
|-------|-------------|
| [hyva-compile-tailwind-css](skills/hyva-compile-tailwind-css/) | Compile Tailwind CSS for Hyva themes |
| [hyva-exec-shell-cmd](skills/hyva-exec-shell-cmd/) | Detect development environment (Warden, docker-magento, local) and execute commands with appropriate wrappers |
| [hyva-theme-list](skills/hyva-theme-list/) | List all Hyva theme paths in a Magento 2 project |

## License

Licensed under the OSL-3.0.

---

Copyright (c) Hyva Themes https://hyva.io. All rights reserved.
