#!/usr/bin/env bash
# update_profiles.sh
# Safely update user shell profiles to avoid errors from missing third-party profiles
# - backs up existing files
# - replaces unconditional omarchy sourcing with a guarded source
# - ensures ~/.bashrc sources ~/.dotfiles/dotfiles/bashrc if present

set -euo pipefail

TS=$(date +%Y%m%d%H%M%S)
FILES=("$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.profile" "$HOME/.zshrc")

for f in "${FILES[@]}"; do
  if [ -f "$f" ]; then
    echo "Processing $f"
    cp -p "$f" "$f.bak.$TS"

    # Replace any line that references the omarchy rc file with a guarded source
    tmpfile=$(mktemp)
    awk '/omarchy.*bash\/rc/ { print "[ -f ~/.local/share/omarchy/default/bash/rc ] && source ~/.local/share/omarchy/default/bash/rc"; next } { print }' "$f" > "$tmpfile"
    mv "$tmpfile" "$f"

    # If this is ~/.bashrc, ensure it sources the repository-managed bashrc
    if [ "$f" = "$HOME/.bashrc" ]; then
      if ! grep -q "\.dotfiles/dotfiles/bashrc" "$f"; then
        echo '' >> "$f"
        echo '[ -f "$HOME/.dotfiles/dotfiles/bashrc" ] && source "$HOME/.dotfiles/dotfiles/bashrc"' >> "$f"
        echo "Appended source for ~/.dotfiles/dotfiles/bashrc to $f"
      fi
    fi
  fi
done

# Summary
echo "Backups of modified files have been created with suffix .bak.$TS"
echo "If you want these changes in your remote dotfiles repo, commit and push update_profiles.sh or run 'git add/commit' from the repo root." 

echo "Done."