#!/usr/bin/env bash
# ============================================================================
# Legacy PowerShell Cleanup Script
# ⚠️  WARNING: This script will DELETE all PowerShell-related files
# Run this ONLY after verifying the new Linux-native setup works correctly
# ============================================================================

set -e  # Exit on error

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${RED}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║                                                           ║${NC}"
echo -e "${RED}║   ⚠️  DESTRUCTIVE OPERATION - LEGACY CLEANUP ⚠️           ║${NC}"
echo -e "${RED}║                                                           ║${NC}"
echo -e "${RED}║   This will DELETE all PowerShell files and folders      ║${NC}"
echo -e "${RED}║   from the repository.                                    ║${NC}"
echo -e "${RED}║                                                           ║${NC}"
echo -e "${RED}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Function to confirm
confirm() {
    read -p "$(echo -e ${YELLOW}Are you sure you want to continue? [y/N]: ${NC})" -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}Cleanup cancelled.${NC}"
        exit 0
    fi
}

# Show what will be deleted
echo -e "${BLUE}The following items will be deleted:${NC}"
echo ""
echo -e "${YELLOW}Files:${NC}"
echo "  • Microsoft.PowerShell_profile.ps1"
echo "  • powershell.config.json"
echo "  • tools/prepare-commit.bat"
echo "  • tools/install-dependencies.ps1"
echo "  • tools/generate_function_docs.ps1"
echo ""
echo -e "${YELLOW}Directories:${NC}"
echo "  • Core/"
echo "  • Scripts/"
echo "  • Config/ (except starship.toml)"
echo ""

confirm

echo ""
echo -e "${BLUE}Starting cleanup...${NC}"
echo ""

# Function to remove file
remove_file() {
    if [ -f "$1" ]; then
        rm -f "$1"
        echo -e "${GREEN}✓${NC} Removed: $1"
    else
        echo -e "${YELLOW}!${NC} Not found: $1"
    fi
}

# Function to remove directory
remove_dir() {
    if [ -d "$1" ]; then
        rm -rf "$1"
        echo -e "${GREEN}✓${NC} Removed: $1"
    else
        echo -e "${YELLOW}!${NC} Not found: $1"
    fi
}

# Remove PowerShell profile and config
remove_file "Microsoft.PowerShell_profile.ps1"
remove_file "powershell.config.json"

# Remove Core directory (all PowerShell modules)
remove_dir "Core"

# Remove Scripts directory
remove_dir "Scripts"

# Remove tools directory
remove_dir "tools"

# Backup starship.toml before removing Config
if [ -f "Config/starship.toml" ]; then
    mkdir -p dotfiles/config
    mv Config/starship.toml dotfiles/config/starship.toml
    echo -e "${GREEN}✓${NC} Moved: Config/starship.toml → dotfiles/config/starship.toml"
fi

# Remove Config directory (except starship.toml which we moved)
remove_dir "Config"

# Remove any remaining .ps1 files in root
for file in *.ps1; do
    if [ -f "$file" ]; then
        remove_file "$file"
    fi
done

# Remove any .bat files
for file in *.bat; do
    if [ -f "$file" ]; then
        remove_file "$file"
    fi
done

# Remove PowerShell-specific documentation
if [ -f "docs/CUSTOMIZATION.md" ]; then
    if grep -q "PowerShell" "docs/CUSTOMIZATION.md"; then
        remove_file "docs/CUSTOMIZATION.md"
    fi
fi

if [ -f "docs/FunctionReference.md" ]; then
    remove_file "docs/FunctionReference.md"
fi

# Update .github configuration files
echo ""
echo -e "${BLUE}Updating GitHub configuration for Linux environment...${NC}"

if [ -f ".github/dependabot.new.yml" ]; then
    mv .github/dependabot.new.yml .github/dependabot.yml
    echo -e "  ${GREEN}✓${NC} Updated dependabot.yml for GitHub Actions"
fi

if [ -f ".github/codeql-config.new.yml" ]; then
    mv .github/codeql-config.new.yml .github/codeql-config.yml
    echo -e "  ${GREEN}✓${NC} Updated codeql-config.yml for shell scripts"
fi

if [ -f ".github/workflows/generate-docs.yml" ]; then
    remove_file ".github/workflows/generate-docs.yml"
    echo -e "  ${GREEN}✓${NC} Removed PowerShell documentation workflow"
fi

if [ -f ".github/workflows/generate-docs.archived.yml" ]; then
    remove_file ".github/workflows/generate-docs.archived.yml"
fi

echo ""
echo -e "${BLUE}Cleanup completed!${NC}"
echo ""
echo -e "${GREEN}Files kept:${NC}"
echo "  • README.md"
echo "  • SECURITY.md"
echo "  • CONTRIBUTING.md"
echo "  • .gitignore"
echo "  • .github/ (updated for Linux)"
echo "  • .gitmodules (if exists)"
echo "  • LICENSE (if exists)"
echo "  • Makefile"
echo "  • install.sh"
echo "  • cleanup-legacy.sh"
echo "  • migrate.sh"
echo "  • dotfiles/"
echo "  • docs/ (Linux-specific docs)"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Review changes with: git status"
echo "  2. Check diff: git diff"
echo "  3. Commit changes: git commit -F .commit-message"
echo "  4. Test installation on a clean Linux system"
echo ""
