#!/bin/sh
#
# Hyva AI Skills Installer - Individual Skill
# Installs a single Hyva skill (and its dependencies) via symlink
#
# Usage:
#   install-hyva-skill.sh [--copy] <skill-name> [agent]
#
# Examples:
#   install-hyva-skill.sh hyva-child-theme claude
#   install-hyva-skill.sh hyva-theme-list
#   install-hyva-skill.sh --copy hyva-child-theme claude
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
print_error()   { printf '%s[ERROR]%s %s\n' "$RED" "$NC" "$1"; }
print_info()    { printf '%s[INFO]%s %s\n' "$BLUE" "$NC" "$1"; }

# Resolve the real path of the repo root (where this script lives)
REPO_ROOT="$(cd "$(dirname "$0")" && pwd -P)"
SKILLS_SRC="$REPO_ROOT/skills"

# Track installed skills to avoid cycles
INSTALLED_IN_SESSION=""

# Install mode: "symlink" (default) or "copy"
INSTALL_MODE="symlink"

# Known agent dot-directories
KNOWN_AGENT_DIRS=".claude .codex .github .cursor .gemini .opencode"

usage() {
    echo "Usage: $(basename "$0") [--copy] <skill-name> [agent]"
    echo "       $(basename "$0") --list"
    echo ""
    echo "Arguments:"
    echo "  skill-name   Name of the skill to install (e.g. hyva-child-theme)"
    echo "  agent        Target agent: claude, codex, copilot, cursor, gemini, opencode"
    echo "               If omitted, auto-detected or prompted."
    echo ""
    echo "Options:"
    echo "  --copy       Copy skills instead of symlinking (useful for containers)"
    echo "  --list       List all available skill names and exit"
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
    exit 1
}

# Map agent name to its dot-directory
agent_to_dir() {
    case "$1" in
        claude)   echo ".claude" ;;
        codex)    echo ".codex" ;;
        copilot)  echo ".github" ;;
        cursor)   echo ".cursor" ;;
        gemini)   echo ".gemini" ;;
        opencode) echo ".opencode" ;;
        *)
            print_error "Unknown agent: $1" >&2
            echo "Supported agents: claude, codex, copilot, cursor, gemini, opencode" >&2
            exit 1
            ;;
    esac
}

# Read a line from the user (works even when stdin is piped)
prompt_user() {
    if [ ! -t 0 ] && [ ! -c /dev/tty 2>/dev/null ]; then
        print_error "Cannot prompt for input in non-interactive mode."
        print_error "Please specify the agent explicitly: $(basename "$0") <skill-name> <agent>"
        exit 1
    fi
    printf "%s" "$1" > /dev/tty
    read -r REPLY < /dev/tty
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

# Map a dot-directory back to an agent name (for display)
dir_to_agent() {
    case "$1" in
        .claude)   echo "claude" ;;
        .codex)    echo "codex" ;;
        .github)   echo "copilot" ;;
        .cursor)   echo "cursor" ;;
        .gemini)   echo "gemini" ;;
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
    skill_name="$1"
    skill_file="$SKILLS_SRC/$skill_name/SKILL.md"
    if [ ! -f "$skill_file" ]; then
        return
    fi
    # Read the frontmatter (between --- markers) and extract requires line
    sed -n '/^---$/,/^---$/p' "$skill_file" | grep '^requires:' | sed 's/^requires: *//' | tr ',' '\n' | sed 's/^ *//;s/ *$//' | grep . || true
}

# Check if a skill is already installed in the target directory
is_skill_installed() {
    skill_name="$1"
    target_dir="$2"
    [ -e "$target_dir/$skill_name" ]
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

    # Install dependencies
    deps="$(get_requires "$skill_name")"
    if [ -n "$deps" ]; then
        # Use a temp file to avoid subshell variable scoping issues
        dep_file="$(mktemp "${TMPDIR:-/tmp}/hyva-deps.XXXXXX")"
        echo "$deps" > "$dep_file"
        while read -r dep; do
            if [ -z "$dep" ]; then
                continue
            fi
            if is_skill_installed "$dep" "$target_dir"; then
                print_info "Dependency already present: $dep"
                INSTALLED_IN_SESSION="$INSTALLED_IN_SESSION $dep"
            else
                print_info "Installing dependency: $dep (required by $skill_name)"
                install_skill "$dep" "$target_dir" "$skill_name"
            fi
        done < "$dep_file"
        rm -f "$dep_file"
    fi
}

# Prompt the user for global vs local install and set TARGET_DIR
# Args: $1 = agent dot-directory (e.g. .claude)
resolve_target_dir() {
    _agent_dir="$1"
    if [ -d "./$_agent_dir" ]; then
        TARGET_DIR="./$_agent_dir/skills"
    else
        _answer="$(prompt_user "No $_agent_dir directory found in current directory. Install (g)lobally in ~/$_agent_dir/skills or (l)ocally in ./$_agent_dir/skills? [g/l]: ")"
        case "$_answer" in
            l|L|local)
                TARGET_DIR="./$_agent_dir/skills"
                ;;
            *)
                TARGET_DIR="$HOME/$_agent_dir/skills"
                ;;
        esac
    fi
}

# --- Main ---

# Handle --copy flag
if [ "$1" = "--copy" ]; then
    INSTALL_MODE="copy"
    shift
fi

if [ -z "$1" ]; then
    print_error "Skill name required"
    usage
fi

# Handle --list flag
if [ "$1" = "--list" ]; then
    for skill_path in "$SKILLS_SRC"/hyva-*; do
        if [ -d "$skill_path" ]; then
            basename "$skill_path"
        fi
    done
    exit 0
fi

SKILL_NAME="$1"
AGENT="${2:-}"

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
    agent_dir="$(agent_to_dir "$AGENT")"
    resolve_target_dir "$agent_dir"
else
    # No agent specified - try to resolve
    if [ -n "${HYVA_SKILLS_AGENT:-}" ]; then
        # Environment variable set - use it directly
        AGENT="$HYVA_SKILLS_AGENT"
        agent_dir="$(agent_to_dir "$AGENT")"
        resolve_target_dir "$agent_dir"
        print_info "Using agent from HYVA_SKILLS_AGENT: $AGENT"
    else
        # Try auto-detection
        detected_dir="$(detect_agent_dir || true)"
        if [ -n "$detected_dir" ]; then
            detected_agent="$(dir_to_agent "$detected_dir")"
            answer="$(prompt_user "Detected $detected_agent agent ($detected_dir/skills). Install there? [Y/n/agent-name]: ")"
            case "$answer" in
                ""|y|Y|yes|Yes)
                    TARGET_DIR="./$detected_dir/skills"
                    ;;
                n|N|no|No)
                    print_error "Installation cancelled."
                    exit 1
                    ;;
                *)
                    # User specified an alternative agent
                    AGENT="$answer"
                    agent_dir="$(agent_to_dir "$AGENT")"
                    resolve_target_dir "$agent_dir"
                    ;;
            esac
        else
            # Nothing detected, ask the user
            AGENT="$(prompt_user "No agent directory detected. Enter agent name (claude/codex/copilot/cursor/gemini/opencode): ")"
            if [ -z "$AGENT" ]; then
                print_error "No agent specified."
                exit 1
            fi
            agent_dir="$(agent_to_dir "$AGENT")"
            resolve_target_dir "$agent_dir"
        fi
    fi
fi

echo ""
print_info "Installing $SKILL_NAME to $TARGET_DIR"
echo ""

install_skill "$SKILL_NAME" "$TARGET_DIR"

echo ""
print_success "Done!"
