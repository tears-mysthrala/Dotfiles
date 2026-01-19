#!/usr/bin/env bash
# ============================================================================
# MIGRATION EXECUTION SCRIPT
# Run this script to complete the PowerShell to Linux migration
# ============================================================================

set -e

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  PowerShell → Linux Native Migration                      ║"
echo "║  This script will complete the repository transformation  ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Step 1: Backup
echo "[1/6] Creating backup branch..."
git checkout -b backup-powershell 2>/dev/null || git checkout backup-powershell
git add -A
git commit -m "Backup: PowerShell configuration before Linux migration" 2>/dev/null || echo "Already committed"
git checkout main

# Step 2: Make scripts executable
echo "[2/6] Setting execute permissions..."
chmod +x install.sh cleanup-legacy.sh

# Step 3: Replace README and gitignore
echo "[3/6] Replacing README and .gitignore..."
mv README.md README.old.md 2>/dev/null || true
mv README.new.md README.md
mv .gitignore .gitignore.old 2>/dev/null || true
mv .gitignore.new .gitignore
mv docs/INSTALLATION.md docs/INSTALLATION.old.md 2>/dev/null || true
mv docs/INSTALLATION.new.md docs/INSTALLATION.md

# Step 4: Run cleanup
echo "[4/6] Running legacy cleanup (this will delete PowerShell files)..."
read -p "Continue with cleanup? [y/N]: " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    ./cleanup-legacy.sh
else
    echo "Cleanup skipped. Run ./cleanup-legacy.sh manually when ready."
    exit 0
fi

# Step 5: Remove backup files
echo "[5/6] Removing backup files..."
rm -f README.old.md .gitignore.old docs/INSTALLATION.old.md

# Step 6: Git operations
echo "[6/6] Staging changes..."
git add -A

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  Migration Complete!                                       ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Next steps:"
echo "  1. Review changes:  git status"
echo "  2. See diff:        git diff --staged"
echo "  3. Commit:          git commit -F .commit-message"
echo "  4. Push:            git push origin main"
echo ""
echo "To test on Linux:"
echo "  ./install.sh"
echo ""
