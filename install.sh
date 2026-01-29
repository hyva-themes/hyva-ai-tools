#!/bin/sh
#
# Hyva AI Skills Installer
# Installs Hyva development skills for AI coding assistants
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/hyva-themes/hyva-ai-tools/refs/heads/main/install.sh | sh -s claude
#   curl -fsSL https://raw.githubusercontent.com/hyva-themes/hyva-ai-tools/refs/heads/main/install.sh | sh -s codex
#   curl -fsSL https://raw.githubusercontent.com/hyva-themes/hyva-ai-tools/refs/heads/main/install.sh | sh -s copilot
#   curl -fsSL https://raw.githubusercontent.com/hyva-themes/hyva-ai-tools/refs/heads/main/install.sh | sh -s cursor
#   curl -fsSL https://raw.githubusercontent.com/hyva-themes/hyva-ai-tools/refs/heads/main/install.sh | sh -s gemini
#   curl -fsSL https://raw.githubusercontent.com/hyva-themes/hyva-ai-tools/refs/heads/main/install.sh | sh -s opencode
#
# Copyright (c) Hyva Themes https://hyva.io. All rights reserved.
# Licensed under the OSL-3.0

set -e

# Configuration
REPO_URL="${HYVA_SKILLS_REPO_URL:-https://github.com/hyva-themes/hyva-ai-tools.git}"
BRANCH="${HYVA_SKILLS_BRANCH:-main}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Track installed skills for summary
INSTALLED_SKILLS=""

print_header() {
    echo ""
    echo "${BLUE}============================================${NC}"
    echo "${BLUE}  Hyva AI Skills Installer${NC}"
    echo "${BLUE}============================================${NC}"
    echo ""
}

print_success() {
    echo "${GREEN}[OK]${NC} $1"
}

print_warning() {
    echo "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo "${RED}[ERROR]${NC} $1"
}

print_info() {
    echo "${BLUE}[INFO]${NC} $1"
}

usage() {
    echo "Usage: $0 <platform>"
    echo ""
    echo "Platforms:"
    echo "  claude    Install skills for Claude Code (.claude/skills/)"
    echo "  codex     Install skills for Codex (.codex/skills/)"
    echo "  copilot   Install skills for GitHub Copilot (.copilot/skills/)"
    echo "  cursor    Install skills for Cursor (.cursor/skills/)"
    echo "  gemini    Install skills for Gemini (.gemini/skills/)"
    echo "  opencode  Install skills for OpenCode (.opencode/skills/)"
    echo ""
    echo "Examples:"
    echo "  curl -fsSL https://raw.githubusercontent.com/hyva-themes/hyva-ai-tools/refs/heads/main/install.sh | sh -s claude"
    echo "  curl -fsSL https://raw.githubusercontent.com/hyva-themes/hyva-ai-tools/refs/heads/main/install.sh | sh -s codex"
    echo "  curl -fsSL https://raw.githubusercontent.com/hyva-themes/hyva-ai-tools/refs/heads/main/install.sh | sh -s copilot"
    echo "  curl -fsSL https://raw.githubusercontent.com/hyva-themes/hyva-ai-tools/refs/heads/main/install.sh | sh -s cursor"
    echo "  curl -fsSL https://raw.githubusercontent.com/hyva-themes/hyva-ai-tools/refs/heads/main/install.sh | sh -s gemini"
    echo "  curl -fsSL https://raw.githubusercontent.com/hyva-themes/hyva-ai-tools/refs/heads/main/install.sh | sh -s opencode"
    echo ""
    echo "Environment variables:"
    echo "  HYVA_SKILLS_REPO_URL   Custom repository URL"
    echo "  HYVA_SKILLS_BRANCH     Git branch to use (default: main)"
    exit 1
}

get_skills_dir() {
    platform="$1"
    case "$platform" in
        claude)
            echo ".claude/skills"
            ;;
        codex)
            echo ".codex/skills"
            ;;
        copilot)
            echo ".github/skills"
            ;;
        cursor)
            echo ".cursor/skills"
            ;;
        gemini)
            echo ".gemini/skills"
            ;;
        opencode)
            echo ".opencode/skills"
            ;;
        *)
            print_error "Unknown platform: $platform"
            usage
            ;;
    esac
}

check_dependencies() {
    # Check for required commands
    for cmd in curl tar mkdir; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            print_error "Required command '$cmd' not found"
            exit 1
        fi
    done

    # Check for git (optional, for clone method)
    if command -v git >/dev/null 2>&1; then
        HAS_GIT=1
    else
        HAS_GIT=0
        print_warning "git not found, will use tarball download"
    fi
}

detect_project_root() {
    # Try to find Magento root by looking for app/etc/env.php
    current_dir="$(pwd)"

    while [ "$current_dir" != "/" ]; do
        if [ -f "$current_dir/app/etc/env.php" ]; then
            echo "$current_dir"
            return 0
        fi
        current_dir="$(dirname "$current_dir")"
    done

    # Fall back to current directory
    echo "$(pwd)"
}

# Install a single skill (replaces existing if present)
# Args: $1 = source path, $2 = destination directory, $3 = skill name
install_skill() {
    src_path="$1"
    dest_dir="$2"
    skill="$3"
    dest_path="$dest_dir/$skill"

    if [ -d "$dest_path" ]; then
        rm -rf "$dest_path"
        cp -r "$src_path" "$dest_path"
        print_success "Updated $skill"
    else
        cp -r "$src_path" "$dest_path"
        print_success "Installed $skill"
    fi

    INSTALLED_SKILLS="$INSTALLED_SKILLS $skill"
}

# Install all hyva-* skills from source directory
# Args: $1 = repo root directory, $2 = destination skills directory
install_skills_from_repo() {
    repo_dir="$1"
    dest_dir="$2"
    skills_src="$repo_dir/skills"

    if [ ! -d "$skills_src" ]; then
        print_error "Skills directory not found in repository"
        return 1
    fi

    # Find and install all hyva-* skill directories
    found_skills=0
    for skill_path in "$skills_src"/hyva-*; do
        if [ -d "$skill_path" ]; then
            skill=$(basename "$skill_path")
            install_skill "$skill_path" "$dest_dir" "$skill"
            found_skills=1
        fi
    done

    if [ "$found_skills" = "0" ]; then
        print_warning "No hyva-* skills found in repository"
    fi

    return 0
}

install_via_git() {
    skills_dir="$1"
    tmp_dir=$(mktemp -d)

    print_info "Cloning repository..."
    git clone --depth 1 --branch "$BRANCH" "$REPO_URL" "$tmp_dir" 2>/dev/null || {
        print_error "Failed to clone repository"
        rm -rf "$tmp_dir"
        return 1
    }

    install_skills_from_repo "$tmp_dir" "$skills_dir"
    result=$?

    rm -rf "$tmp_dir"
    return $result
}

install_via_tarball() {
    skills_dir="$1"
    tmp_dir=$(mktemp -d)

    # Construct tarball URL for GitHub
    tarball_url="$REPO_URL/archive/refs/heads/$BRANCH.tar.gz"

    print_info "Downloading from $tarball_url..."
    curl -fsSL "$tarball_url" -o "$tmp_dir/skills.tar.gz" || {
        print_error "Failed to download skills archive"
        rm -rf "$tmp_dir"
        return 1
    }

    print_info "Extracting archive..."
    tar -xzf "$tmp_dir/skills.tar.gz" -C "$tmp_dir" || {
        print_error "Failed to extract archive"
        rm -rf "$tmp_dir"
        return 1
    }

    # Find the extracted directory (usually repo-name-branch)
    extracted_dir=$(find "$tmp_dir" -maxdepth 1 -type d -name "*-*" | head -1)

    if [ -z "$extracted_dir" ]; then
        print_error "Could not find extracted directory"
        rm -rf "$tmp_dir"
        return 1
    fi

    install_skills_from_repo "$extracted_dir" "$skills_dir"
    result=$?

    rm -rf "$tmp_dir"
    return $result
}

main() {
    print_header

    # Check for platform argument
    if [ -z "$1" ]; then
        print_error "Platform argument required"
        usage
    fi

    platform="$1"
    skills_dir_name=$(get_skills_dir "$platform")

    print_info "Installing skills for: $platform"

    # Check dependencies
    check_dependencies

    # Detect project root
    project_root=$(detect_project_root)
    print_info "Project root: $project_root"

    # Full path to skills directory
    skills_dir="$project_root/$skills_dir_name"

    # Create skills directory if it doesn't exist
    if [ ! -d "$skills_dir" ]; then
        mkdir -p "$skills_dir"
        print_success "Created $skills_dir_name directory"
    else
        print_info "Skills directory already exists"
    fi

    # Try git clone first, fall back to tarball
    if [ "$HAS_GIT" = "1" ]; then
        install_via_git "$skills_dir" || install_via_tarball "$skills_dir"
    else
        install_via_tarball "$skills_dir"
    fi

    echo ""
    echo "${GREEN}============================================${NC}"
    echo "${GREEN}  Installation complete!${NC}"
    echo "${GREEN}============================================${NC}"
    echo ""
    echo "Skills installed to: $skills_dir"
    echo ""
    if [ -n "$INSTALLED_SKILLS" ]; then
        echo "Installed skills:"
        for skill in $INSTALLED_SKILLS; do
            echo "  - $skill"
        done
    else
        echo "No skills were installed."
    fi
    echo ""
    echo "You can now use these skills with your AI assistant."
    echo "Try: \"Create a Hyva child theme\" or \"Add a CMS component\""
    echo ""
}

main "$@"
