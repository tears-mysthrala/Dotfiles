# Migration Commands - PowerShell to Linux Native
# Execute these commands in order to complete the migration

## PHASE 1: Backup (Optional but Recommended)
```powershell
# Create a backup branch before starting
git checkout -b backup-powershell
git add -A
git commit -m "Backup: PowerShell configuration before Linux migration"
git checkout main
```

## PHASE 2: Execute Migration
```bash
# Make scripts executable
chmod +x install.sh cleanup-legacy.sh

# Replace README and .gitignore
mv README.md README.old.md
mv README.new.md README.md
mv .gitignore .gitignore.old
mv .gitignore.new .gitignore

# Run the cleanup script to remove PowerShell legacy files
./cleanup-legacy.sh
```

## PHASE 3: Final Cleanup and Commit
```bash
# Remove backup files if everything looks good
rm -f README.old.md .gitignore.old

# Stage all changes
git add -A

# Review what will be committed
git status
git diff --staged

# Commit the migration
git commit -m "feat: Complete migration to Linux-native shell configuration

- Replaced PowerShell scripts with POSIX-compliant shell scripts
- Added Makefile-based installation system
- Implemented multi-distro package manager detection
- Added modern CLI tools (starship, zoxide, fzf, eza, bat)
- Created modular shell configuration (aliases, functions, exports)
- Added bootstrap installer (install.sh)
- Updated documentation for Linux environment

BREAKING CHANGE: This removes all PowerShell-specific code and Windows compatibility.
The repository is now exclusively for Linux-based systems."

# Push to remote
git push origin main
```

## PHASE 4: Test on Linux System
```bash
# On a Linux machine, test the installation:
git clone https://github.com/tears-mysthrala/Dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh

# Restart your shell
exec bash
# or
exec zsh

# Verify tools are working
starship --version
zoxide --version
fzf --version
eza --version
bat --version

# Test aliases
ls
ll
la
cat README.md

# Test functions
sysinfo
upgrade --help
```

## PHASE 5: Optional - Clean Up Git History
```bash
# If you want to remove the backup branch
git branch -D backup-powershell

# If you want to clean up the remote backup (if pushed)
git push origin --delete backup-powershell
```

## Alternative: Manual Cleanup Commands
If you prefer to manually delete files instead of using cleanup-legacy.sh:

```bash
# Remove PowerShell files
rm -f Microsoft.PowerShell_profile.ps1
rm -f powershell.config.json
rm -f *.ps1
rm -f *.bat

# Remove PowerShell directories
rm -rf Core/
rm -rf Scripts/
rm -rf tools/

# Backup and remove Config (keep starship.toml)
mkdir -p dotfiles/config
mv Config/starship.toml dotfiles/config/starship.toml 2>/dev/null || true
rm -rf Config/

# Keep only Linux-native files
# These should remain:
# - README.md (new)
# - .gitignore (new)
# - CONTRIBUTING.md
# - SECURITY.md
# - Makefile
# - install.sh
# - cleanup-legacy.sh
# - dotfiles/
```

## Verification Checklist
- [ ] All PowerShell (.ps1) files removed
- [ ] Core/ directory removed
- [ ] Scripts/ directory removed
- [ ] Config/ moved to dotfiles/config/
- [ ] New shell scripts in dotfiles/shell/ created
- [ ] Makefile created and tested
- [ ] install.sh created and tested
- [ ] README.md updated for Linux
- [ ] .gitignore updated for Linux/Shell patterns
- [ ] Git repository committed and pushed
- [ ] Installation tested on at least one Linux distribution

## Rollback (if needed)
```bash
# If something goes wrong, restore from backup:
git checkout backup-powershell
git reset --hard
git checkout main
git reset --hard backup-powershell
```
