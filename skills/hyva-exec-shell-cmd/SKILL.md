---
name: hyva-exec-shell-cmd
description: Utility skill to detect Magento development environment and determine command wrapper. This skill should be used by other skills that need to execute shell commands in the Magento environment. It detects Warden, docker-magento, DDEV, and local environments and provides the appropriate command wrapper.
---

# Execute Shell Commands in Magento Environment

This utility skill detects the Magento development environment and provides the appropriate command wrapper for executing shell commands.

## Usage

Other skills should reference this skill when they need to execute commands in the Magento environment. The detected wrapper ensures commands run in the correct context (container or local).

## Step 1: Detect Environment

**Important:** Execute this script from the Magento project root directory, or provide the path as an argument.

Run this detection once at the start of any skill that needs to execute shell commands:

```bash
<skill_path>/scripts/detect_env.sh [magento_root_path]
```

Where `<skill_path>` is the directory containing this SKILL.md file.

The optional `magento_root_path` argument specifies the Magento installation directory. If omitted, the script uses the current working directory.

Output: `warden`, `docker-magento`, `ddev`, or `local`

## Step 2: Apply Command Wrapper

Based on detected environment, wrap commands as follows:

| Environment | Command Wrapper | Description |
|-------------|-----------------|-------------|
| Warden | `warden env exec -T php-fpm bash -c "<command>"` | Docker environment managed by Warden |
| docker-magento | `bin/clinotty bash -c "<command>"` | Mark Shust's docker-magento setup |
| DDEV | `ddev exec <command>` | DDEV containerized environment |
| Local | Run `<command>` directly | Native environment without containers |

## Examples

### Single command

```bash
# Warden
warden env exec -T php-fpm bash -c "bin/magento cache:clean"

# docker-magento
bin/clinotty bash -c "bin/magento cache:clean"

# DDEV
ddev exec bin/magento cache:clean

# Local
bin/magento cache:clean
```

### Command with directory change

```bash
# Warden
warden env exec -T php-fpm bash -c "cd vendor/hyva-themes/magento2-default-theme/web/tailwind && npm run build"

# docker-magento
bin/clinotty bash -c "cd vendor/hyva-themes/magento2-default-theme/web/tailwind && npm run build"

# DDEV
ddev exec bash -c "vendor/hyva-themes/magento2-default-theme/web/tailwind && npm run build"

# Local
cd vendor/hyva-themes/magento2-default-theme/web/tailwind && npm run build
```

## Commands That Do NOT Require Wrapping

Some commands run on the host system and should NOT be wrapped:

- `composer` commands (runs on host, not in container)
- `git` commands
- File operations on the host filesystem (`ls`, `find`, `cp` for files accessible from host)
- `warden` CLI commands
- `ddev` CLI commands

## Integration Pattern

Skills that need to execute commands should:

1. Reference this skill: "Use the `hyva-exec-shell-cmd` skill to determine the command wrapper"
2. Detect environment once using Step 1
3. Store the wrapper pattern for use throughout the skill
4. Apply the wrapper to all container commands per Step 2

## Running a Bundled Skill Script Inside the Environment

Some skills ship a helper script (e.g. a PHP script under `scripts/`) that must run
through a PHP/Node interpreter. On a hardened host there is no local interpreter, and
a skill installed at user level (`~/.../skills/...`) is not inside the project, so the
container can't see it. **Do not** copy the script into the project tree: how files
reach the container differs across environments (bind mounts, Mutagen, named volumes)
and some paths are not synced at all (e.g. Warden serves `var/`, `generated/`,
`pub/static`, `pub/media` from separate volumes, so a host-written file there never
appears in the container).

Instead, **stream the script into the interpreter over stdin** — this is independent
of the mount/sync strategy, needs no temp file, and needs no cleanup:

1. Detect the environment (Step 1) and resolve the wrapper (Step 2).
2. **Containerized env** — pipe the script to `php /dev/stdin` through the wrapper
   (use the non-TTY `-T` exec so stdin is forwarded). `<skill_path>` is the directory
   containing the calling skill's SKILL.md:

   ```bash
   # Warden
   cat "<skill_path>/scripts/<script>.php" | warden env exec -T php-fpm bash -c "php /dev/stdin [args]"

   # docker-magento
   cat "<skill_path>/scripts/<script>.php" | bin/clinotty bash -c "php /dev/stdin [args]"

   # DDEV
   cat "<skill_path>/scripts/<script>.php" | ddev exec bash -c "php /dev/stdin [args]"
   ```

   The script runs with the container's working directory at the project root, so a
   script that locates the project via `getcwd()` works unchanged. Capture stdout for
   the result.

   **Script constraints for this method:** the script must not also read from stdin
   (stdin carries the script itself), and must not rely on `__FILE__`/`__DIR__` (it
   is `/dev/stdin`) — locate project files via `getcwd()` instead.
3. **`local` env**: the host has no interpreter (removed during hardening). Do not
   attempt to run the script directly — report that a containerized dev environment
   (or a local interpreter) is required for this step.

<!-- Copyright © Hyvä Themes https://hyva.io. All rights reserved. Licensed under OSL 3.0 -->
