#!/bin/sh
#
# Hyva AI Skills Installer - Individual Skill
# Installs a single Hyva skill (and its dependencies) via symlink
#
# Usage:
#   install-hyva-skill.sh [--copy] [--project|--global] <skill-name> [agent]
#   install-hyva-skill.sh --list
#
# Examples:
#   install-hyva-skill.sh hyva-child-theme claude
#   install-hyva-skill.sh hyva-theme-list
#   install-hyva-skill.sh --copy hyva-child-theme claude
#   install-hyva-skill.sh --project hyva-child-theme codex
#
# Without --project or --global the installer asks where to install.
#
# Environment variables:
#   HYVA_SKILLS_AGENT   Default agent when not specified (e.g. "claude")
#
# Copyright (c) Hyva Themes https://hyva.io. All rights reserved.
# Licensed under the OSL-3.0

set -e

# Colors for output (assigned via printf for POSIX portability)
RED=$(printf '\033[0;31m')
GREEN=$(printf '\033[0;32m')
YELLOW=$(printf '\033[0;33m')
BLUE=$(printf '\033[0;34m')
NC=$(printf '\033[0m')

print_success() { printf '%s[OK]%s %s\n' "$GREEN" "$NC" "$1"; }
print_warning() { printf '%s[WARN]%s %s\n' "$YELLOW" "$NC" "$1"; }
print_error()   { printf '%s[ERROR]%s %s\n' "$RED" "$NC" "$1" >&2; }
print_info()    { printf '%s[INFO]%s %s\n' "$BLUE" "$NC" "$1"; }

# Resolve the real path of the repo root (where this script lives)
REPO_ROOT="$(cd "$(dirname "$0")" && pwd -P)"
SKILLS_SRC="$REPO_ROOT/skills"

# Track installed skills to avoid cycles
INSTALLED_IN_SESSION=""

# Install mode: "symlink" (default) or "copy"
INSTALL_MODE="symlink"

# Install location: "project", "global", or empty to ask the user
INSTALL_SCOPE=""

# Known agent dot-directories
KNOWN_AGENT_DIRS=".claude .agents .codex .github .cursor .gemini .junie .opencode"

usage() {
    echo "Usage: $(basename "$0") [--copy] [--project|--global] <skill-name> [agent]"
    echo "       $(basename "$0") --list"
    echo ""
    echo "Arguments:"
    echo "  skill-name   Name of the skill to install (e.g. hyva-child-theme)"
    echo "  agent        Target agent: claude, codex, copilot, cursor, gemini, antigravity, junie, opencode"
    echo "               (antigravity is an alias for gemini)"
    echo "               If omitted, auto-detected or prompted."
    echo ""
    echo "Options:"
    echo "  --copy       Copy skills instead of symlinking (useful for containers)"
    echo "  --project    Install into the current project (./) without asking"
    echo "  --global     Install into the home directory (~/) without asking"
    echo "               Without --project or --global the installer always asks."
    echo "  --list       List all available skill names and exit"
    echo "  -h, --help   Show this help"
    echo ""
    echo "Environment variables:"
    echo "  HYVA_SKILLS_AGENT   Default agent when not specified on command line"
    echo ""
    echo "Available skills:"
    for skill_path in "$SKILLS_SRC"/hyva-*; do
        if [ -d "$skill_path" ]; then
            echo "  $(basename "$skill_path")"
        fi
    done
    exit "${1:-1}"
}

# Map agent name to its own dot-directory. Exits on an unknown agent name.
agent_to_dir() {
    case "$1" in
        claude)   echo ".claude" ;;
        codex)    echo ".codex" ;;
        copilot)  echo ".github" ;;
        cursor)   echo ".cursor" ;;
        gemini|antigravity) echo ".gemini" ;;
        junie)    echo ".junie" ;;
        opencode) echo ".opencode" ;;
        *)
            print_error "Unknown agent: $1"
            echo "Supported agents: claude, codex, copilot, cursor, gemini, antigravity, junie, opencode" >&2
            exit 1
            ;;
    esac
}

# Abort with an error if the agent name is unknown.
# Call this directly, not inside $(...), so that the exit stops the script.
validate_agent() {
    agent_to_dir "$1" >/dev/null
}

# Dot-directory for a project (local) install.
# Codex, Gemini CLI and Antigravity all read .agents/skills in a project, and it is
# the only project location Antigravity reads. An existing .codex/skills or
# .gemini/skills directory from an older setup keeps being used.
agent_local_dir() {
    _native="$(agent_to_dir "$1")"
    case "$1" in
        codex|gemini|antigravity)
            if [ -d "./$_native/skills" ]; then
                echo "$_native"
            else
                echo ".agents"
            fi
            ;;
        *) echo "$_native" ;;
    esac
}

# Dot-directory for a global (home directory) install.
# Codex reads ~/.agents/skills; an existing ~/.codex/skills keeps being used.
# Gemini CLI and Antigravity CLI read ~/.gemini/skills.
agent_global_dir() {
    _native="$(agent_to_dir "$1")"
    case "$1" in
        codex)
            if [ -d "$HOME/.codex/skills" ]; then
                echo ".codex"
            else
                echo ".agents"
            fi
            ;;
        *) echo "$_native" ;;
    esac
}

# Read a line from the user (works even when stdin is piped)
prompt_user() {
    # /dev/tty can exist without being usable (no controlling terminal), so try to open it
    if ! { : > /dev/tty; } 2>/dev/null; then
        print_error "Cannot prompt for input without a terminal."
        print_error "Specify the agent and the location explicitly: $(basename "$0") --project|--global <skill-name> <agent>"
        exit 1
    fi
    printf "%s" "$1" > /dev/tty
    if ! read -r REPLY < /dev/tty; then
        echo "" > /dev/tty
        print_error "Installation cancelled."
        exit 1
    fi
    echo "$REPLY"
}

# Auto-detect agent directory from CWD
# Checks only known agent dot-directories for a skills subdirectory
detect_agent_dir() {
    for dot_dir in $KNOWN_AGENT_DIRS; do
        if [ -d "./$dot_dir/skills" ]; then
            echo "$dot_dir"
            return 0
        fi
    done
    return 1
}

# Map a dot-directory back to an agent name.
# .agents is not listed: it is shared by codex, gemini and antigravity.
dir_to_agent() {
    case "$1" in
        .claude)   echo "claude" ;;
        .codex)    echo "codex" ;;
        .github)   echo "copilot" ;;
        .cursor)   echo "cursor" ;;
        .gemini)   echo "gemini" ;;
        .junie)    echo "junie" ;;
        .opencode) echo "opencode" ;;
        *)         echo "$1" ;;
    esac
}

# Portable readlink: resolve the target of a symlink
# Falls back to parsing ls -l output when readlink is not available
resolve_symlink() {
    if command -v readlink >/dev/null 2>&1; then
        readlink "$1" 2>/dev/null || true
    else
        ls -l "$1" 2>/dev/null | sed 's/.*-> //' || true
    fi
}

# Extract the requires: field from a skill's SKILL.md frontmatter
get_requires() {
    skill_file="$SKILLS_SRC/$1/SKILL.md"
    if [ ! -f "$skill_file" ]; then
        return
    fi
    # Read the frontmatter (between --- markers) and extract requires line
    sed -n '/^---$/,/^---$/p' "$skill_file" | grep '^requires:' | sed 's/^requires: *//' | tr ',' '\n' | sed 's/^ *//;s/ *$//' | grep . || true
}

# Check if a skill is already installed in the target directory
is_skill_installed() {
    [ -e "$2/$1" ]
}

# Install a single skill as a symlink
# Args: $1 = skill name, $2 = target skills directory, $3 = parent skill (optional, for error context)
install_skill() {
    skill_name="$1"
    target_dir="$2"
    parent_skill="${3:-}"
    src="$SKILLS_SRC/$skill_name"

    if [ ! -d "$src" ]; then
        if [ -n "$parent_skill" ]; then
            print_error "Skill not found: $skill_name (required by $parent_skill)"
        else
            print_error "Skill not found: $skill_name"
        fi
        return 1
    fi

    # Skip if already handled this session (cycle prevention)
    case " $INSTALLED_IN_SESSION " in
        *" $skill_name "*) return 0 ;;
    esac
    INSTALLED_IN_SESSION="$INSTALLED_IN_SESSION $skill_name"

    # Create target directory if needed
    mkdir -p "$target_dir"

    target="$target_dir/$skill_name"

    if [ "$INSTALL_MODE" = "copy" ]; then
        _verb="Installed"
        if [ -d "$target" ]; then
            # Atomically replace: copy to a temp dir beside the target, then rename
            _tmp_target="${target}.tmp.$$"
            rm -rf "$_tmp_target"
            cp -r "$src" "$_tmp_target"
            rm -rf "$target"
            mv "$_tmp_target" "$target"
            _verb="Updated"
        else
            cp -r "$src" "$target"
        fi
        print_success "$_verb (copy): $skill_name"
    else
        if [ -L "$target" ]; then
            # Already a symlink - check if it points to the right place
            existing="$(resolve_symlink "$target")"
            if [ "$existing" = "$src" ]; then
                print_info "Already installed: $skill_name"
            else
                rm -f "$target"
                ln -s "$src" "$target"
                print_success "Updated symlink: $skill_name"
            fi
        elif [ -e "$target" ]; then
            print_warning "$skill_name exists but is not a symlink, skipping"
            print_warning "  Remove $target manually to reinstall as symlink"
        else
            ln -s "$src" "$target"
            print_success "Installed: $skill_name"
        fi
    fi

    # Install dependencies. The recursive call overwrites the variables above, so
    # only the positional parameters ($1 = this skill, $2 = target directory) are
    # used from here on. Skill names contain no whitespace or glob characters.
    for dep in $(get_requires "$1"); do
        if is_skill_installed "$dep" "$2"; then
            print_info "Dependency already present: $dep"
            INSTALLED_IN_SESSION="$INSTALLED_IN_SESSION $dep"
        else
            print_info "Installing dependency: $dep (required by $1)"
            install_skill "$dep" "$2" "$1"
        fi
    done
}

# Set INSTALL_SCOPE to "project" or "global".
# Always asks the user, unless --project or --global was given.
# Args: $1 = project location, $2 = global location (both for display)
choose_scope() {
    while [ -z "$INSTALL_SCOPE" ]; do
        _answer="$(prompt_user "Install in the (p)roject at $1 or (g)lobally at $2? [p/g]: ")"
        case "$_answer" in
            p|P|project|l|L|local) INSTALL_SCOPE="project" ;;
            g|G|global)            INSTALL_SCOPE="global" ;;
            *)                     print_warning "Please answer p or g." ;;
        esac
    done
}

# Set TARGET_DIR for an agent
# Args: $1 = agent name (e.g. claude)
resolve_target_dir() {
    validate_agent "$1"
    _local_dir="$(agent_local_dir "$1")"
    _global_dir="$(agent_global_dir "$1")"
    choose_scope "./$_local_dir/skills" "~/$_global_dir/skills"
    if [ "$INSTALL_SCOPE" = "project" ]; then
        TARGET_DIR="./$_local_dir/skills"
    else
        TARGET_DIR="$HOME/$_global_dir/skills"
    fi
}

# Set TARGET_DIR after .agents/skills was detected in the project.
# The project directory is shared by codex, gemini and antigravity, but their
# global directories differ, so a global install needs to know the agent.
resolve_shared_target_dir() {
    choose_scope "./.agents/skills" "the agent's directory in ~/"
    if [ "$INSTALL_SCOPE" = "project" ]; then
        TARGET_DIR="./.agents/skills"
    else
        AGENT="$(prompt_user "Global install for which agent? (codex/gemini/antigravity): ")"
        validate_agent "$AGENT"
        TARGET_DIR="$HOME/$(agent_global_dir "$AGENT")/skills"
    fi
}

list_skills() {
    for skill_path in "$SKILLS_SRC"/hyva-*; do
        if [ -d "$skill_path" ]; then
            basename "$skill_path"
        fi
    done
}

set_scope() {
    if [ -n "$INSTALL_SCOPE" ] && [ "$INSTALL_SCOPE" != "$1" ]; then
        print_error "--project and --global cannot be combined"
        exit 1
    fi
    INSTALL_SCOPE="$1"
}

# --- Main ---

# Parse arguments. Options may appear before, between or after the positional arguments.
SKILL_NAME=""
AGENT=""
for arg in "$@"; do
    case "$arg" in
        --copy)            INSTALL_MODE="copy" ;;
        --project|--local) set_scope "project" ;;
        --global)          set_scope "global" ;;
        --list)            list_skills; exit 0 ;;
        -h|--help)         usage 0 ;;
        -*)
            print_error "Unknown option: $arg"
            usage
            ;;
        *)
            if [ -z "$SKILL_NAME" ]; then
                SKILL_NAME="$arg"
            elif [ -z "$AGENT" ]; then
                AGENT="$arg"
            else
                print_error "Unexpected argument: $arg"
                usage
            fi
            ;;
    esac
done

if [ -z "$SKILL_NAME" ]; then
    print_error "Skill name required"
    usage
fi

# Validate skill name contains no path separators or traversal sequences
case "$SKILL_NAME" in
    */* | *..*)
        print_error "Invalid skill name: $SKILL_NAME (must not contain '/' or '..')"
        exit 1
        ;;
esac

# Validate the skill exists in the repo
if [ ! -d "$SKILLS_SRC/$SKILL_NAME" ]; then
    print_error "Unknown skill: $SKILL_NAME"
    echo ""
    echo "Available skills:"
    for skill_path in "$SKILLS_SRC"/hyva-*; do
        if [ -d "$skill_path" ]; then
            echo "  $(basename "$skill_path")"
        fi
    done
    exit 1
fi

# Resolve agent and target directory
if [ -n "$AGENT" ]; then
    # Agent explicitly provided
    resolve_target_dir "$AGENT"
else
    # No agent specified - try to resolve
    if [ -n "${HYVA_SKILLS_AGENT:-}" ]; then
        # Environment variable set - use it directly
        AGENT="$HYVA_SKILLS_AGENT"
        resolve_target_dir "$AGENT"
        print_info "Using agent from HYVA_SKILLS_AGENT: $AGENT"
    else
        # Try auto-detection
        detected_dir="$(detect_agent_dir || true)"
        if [ -n "$detected_dir" ]; then
            if [ "$detected_dir" = ".agents" ]; then
                answer="$(prompt_user "Detected .agents/skills (shared by codex, gemini and antigravity). Install there? [Y/n/agent-name]: ")"
            else
                detected_agent="$(dir_to_agent "$detected_dir")"
                answer="$(prompt_user "Detected $detected_agent agent ($detected_dir/skills). Install for this agent? [Y/n/agent-name]: ")"
            fi
            case "$answer" in
                ""|y|Y|yes|Yes)
                    if [ "$detected_dir" = ".agents" ]; then
                        resolve_shared_target_dir
                    else
                        AGENT="$detected_agent"
                        resolve_target_dir "$AGENT"
                    fi
                    ;;
                n|N|no|No)
                    print_error "Installation cancelled."
                    exit 1
                    ;;
                *)
                    # User specified an alternative agent
                    AGENT="$answer"
                    resolve_target_dir "$AGENT"
                    ;;
            esac
        else
            # Nothing detected, ask the user
            AGENT="$(prompt_user "No agent directory detected. Enter agent name (claude/codex/copilot/cursor/gemini/antigravity/junie/opencode): ")"
            if [ -z "$AGENT" ]; then
                print_error "No agent specified."
                exit 1
            fi
            resolve_target_dir "$AGENT"
        fi
    fi
fi

echo ""
print_info "Installing $SKILL_NAME to $TARGET_DIR"
echo ""

install_skill "$SKILL_NAME" "$TARGET_DIR"

echo ""
print_success "Done!"
