# Design: upgrade() function rewrite

**Date:** 2026-03-09
**File to modify:** `~/.dotfiles/dotfiles/shell/functions.sh`

## Goal

Replace the current `upgrade()` function with a comprehensive "lazy alias" that updates the entire system — packages, language tools, and dotfiles — in one command, with a clean deferred summary at the end.

## Requirements

- One command updates everything
- Continues on failure, never stops mid-run
- Deferred output: show only the active step during execution, full summary table at the end
- For known failure modes, print the exact fix command in the summary
- Multi-distro: Arch Linux (yay/paru/pacman), Fedora/Proxmox (dnf), Debian (apt), others
- Updates dotfiles repo (git pull in ~/.dotfiles) and re-sources shell via `exec bash`

## Architecture

### System package manager detection (step 1)

Priority order for Arch:
1. `yay` → `yay -Syu` (covers pacman + AUR)
2. `paru` → `paru -Syu`
3. `pacman` → `sudo pacman -Syu`

Other distros:
- `dnf` → `sudo dnf upgrade -y`
- `apt` → `sudo apt update && sudo apt upgrade -y`
- `zypper` → `sudo zypper refresh && sudo zypper update -y`
- `apk` → `sudo apk update && sudo apk upgrade`

### Steps (in order)

| # | Name | Command | Condition |
|---|------|---------|-----------|
| 1 | system | detected above | always |
| 2 | uv tools | `uv tool upgrade --all` | uv installed |
| 3 | gem | `gem update && gem cleanup` | gem installed |
| 4 | cargo | `cargo install-update -a` | cargo + cargo-install-update installed |
| 5 | pipx | `pipx upgrade-all` | pipx installed |
| 6 | npm globals | `npm update -g` | npm installed |
| 7 | flatpak | `flatpak update -y` | flatpak installed |
| 8 | dotfiles | `git pull` in ~/.dotfiles | always |

### Runner pattern

```
_upgrade_run_step <name> <function>
  - records start time
  - runs function, captures exit code
  - records elapsed time
  - on failure: stores name + known fix command in error array
  - appends result row to results array (deferred)
```

### Output during execution

```
🔄 Actualizando sistema...

[1/8] yay...
[2/8] uv tools...
...
```

### Deferred summary (after all steps)

```
──────────────────────────────────────
  ✅ yay              47 pkgs   2m 14s
  ✅ uv tools          3 pkgs   0m 08s
  ❌ gem                        0m 03s
  ...
  ✅ dotfiles          3 commits → exec bash

7/8 completados · 1 fallo

  gem → gem update --system && gem update
──────────────────────────────────────
```

### Known fix commands

| Step | Known failure | Fix command |
|------|--------------|-------------|
| yay/pacman | file conflicts | `yay -Syu --overwrite '*'` |
| npm | peer deps broken | `npm install -g npm@latest` |
| gem | rubygems outdated | `gem update --system && gem update` |
| cargo | cargo-install-update missing | `cargo install cargo-update` |
| dotfiles | merge conflict | `cd ~/.dotfiles && git status` |

### Dotfiles re-source

If `git pull` brings new commits → `exec bash` (replaces current bash process cleanly, avoids duplicate aliases).

## What is NOT changed

- `detect_package_manager()` — preserved for use by `cleanup()`
- All other functions in `functions.sh`
- No new files created

## Future

Partial update flags (`upgrade --system`, `upgrade --tools`) are out of scope for this iteration but trivially addable by filtering the steps array.
