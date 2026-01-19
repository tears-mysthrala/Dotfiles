# Installation Guide

Complete guide for installing the Linux-native dotfiles configuration.

## Prerequisites

- A Linux-based operating system
- Internet connection
- `curl` or `wget` (for downloading tools)

## Quick Install (Recommended)

```bash
# Clone the repository
git clone https://github.com/tears-mysthrala/Dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# Run the installer
chmod +x install.sh
./install.sh
```

## Manual Installation

### Step 1: Install Dependencies

#### Debian/Ubuntu
```bash
sudo apt update
sudo apt install -y make git curl build-essential
```

#### Fedora
```bash
sudo dnf install -y make git curl gcc
```

#### Arch Linux
```bash
sudo pacman -Sy --noconfirm make git curl base-devel
```

#### openSUSE
```bash
sudo zypper install -y make git curl gcc
```

### Step 2: Install Modern CLI Tools

```bash
# Install all tools at once
make deps

# Or install individually:
make starship
make zoxide
make fzf
make eza
make bat
```

### Step 3: Create Symbolic Links

```bash
make link
```

This creates symlinks in `~/.config/shell/` for:
- `aliases.sh`
- `functions.sh`
- `exports.sh`

### Step 4: Configure Your Shell

```bash
make config
```

This automatically adds initialization code to:
- `~/.bashrc` (for Bash)
- `~/.zshrc` (for Zsh)

### Step 5: Reload Your Shell

```bash
# For Bash
source ~/.bashrc

# For Zsh
source ~/.zshrc

# Or simply restart your terminal
exec bash  # or exec zsh
```

## Customization

### Local Overrides

Create local configuration files that won't be tracked by git:

```bash
# Custom exports
touch ~/.config/shell/exports.local.sh
echo 'export MY_VAR="value"' >> ~/.config/shell/exports.local.sh

# Custom aliases
touch ~/.config/shell/aliases.local.sh
echo 'alias myalias="command"' >> ~/.config/shell/aliases.local.sh

# Custom functions
touch ~/.config/shell/functions.local.sh
```

### Starship Prompt

The Starship configuration is linked from `dotfiles/config/starship.toml`.

To customize:
```bash
# Edit the main config
nano ~/.config/starship.toml

# Or create a local override
cp ~/.config/starship.toml ~/.config/starship.local.toml
nano ~/.config/starship.local.toml
```

### FZF Configuration

FZF is configured in `exports.sh`. To override:

```bash
# Add to ~/.config/shell/exports.local.sh
export FZF_DEFAULT_OPTS='--height 50% --layout=reverse'
```

## Troubleshooting

### Tools Not Found After Installation

Ensure `~/.local/bin` is in your PATH:

```bash
echo $PATH | grep ".local/bin"
```

If not, add to `~/.bashrc` or `~/.zshrc`:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

### Shell Configuration Not Loading

Check if the initialization code was added:

```bash
# For Bash
tail -20 ~/.bashrc

# For Zsh
tail -20 ~/.zshrc
```

You should see a section like:
```bash
# Dotfiles configuration
for file in "$HOME/.config/shell/"{exports,aliases,functions}.sh; do
    [ -f "$file" ] && source "$file"
done
```

### Symbolic Links Broken

Recreate the links:

```bash
make clean
make link
```

### Permission Denied Errors

Ensure scripts are executable:

```bash
chmod +x install.sh cleanup-legacy.sh
```

For tools installed in `~/.local/bin`:

```bash
chmod +x ~/.local/bin/*
```

## Advanced Configuration

### Install Additional Tools

```bash
# Install fd, ripgrep, and delta
make extra-tools
```

### Install Only Specific Tools

```bash
# Using Make
make starship
make zoxide

# Or manually with cargo (if installed)
cargo install starship zoxide bat eza fd-find ripgrep git-delta
```

### Use Different Shell Config Directory

By default, configs go to `~/.config/shell/`. To change:

```bash
# Edit Makefile and change SHELL_CONFIG_DIR
SHELL_CONFIG_DIR := $(HOME)/.myconfig/shell
```

## Uninstallation

### Remove Symbolic Links Only

```bash
make clean
```

### Full Uninstall

```bash
# Remove links
make clean

# Remove installed binaries from ~/.local/bin
rm -f ~/.local/bin/{starship,zoxide,eza,bat,fd}

# Remove shell initialization code from .bashrc/.zshrc
# (You'll need to manually edit these files)

# Remove FZF
~/.fzf/uninstall

# Remove configuration directory
rm -rf ~/.config/shell
```

## Distribution-Specific Notes

### Debian/Ubuntu

- `bat` is installed as `batcat`. The Makefile creates a symlink to `bat`.
- `fd` is installed as `fdfind`. Create alias: `alias fd=fdfind`

### Arch Linux

Most tools are available in official repos or AUR:

```bash
sudo pacman -S starship zoxide fzf bat eza fd ripgrep git-delta
```

### Fedora/RHEL

```bash
sudo dnf install starship zoxide fzf bat eza fd-find ripgrep git-delta
```

### Alpine Linux

```bash
sudo apk add starship zoxide fzf bat eza fd ripgrep git-delta
```

## Next Steps

After installation:

1. **Learn the aliases**: Run `alias` to see all configured shortcuts
2. **Explore functions**: Source your config and use tab completion
3. **Customize**: Add your own aliases and functions to `.local.sh` files
4. **Update**: Run `upgrade` to update all system packages
5. **Clean**: Run `cleanup` to clean package cache

## Getting Help

- Check `make help` for available targets
- Read function source in `dotfiles/shell/functions.sh`
- Review aliases in `dotfiles/shell/aliases.sh`

## References

- [Starship Documentation](https://starship.rs/)
- [Zoxide GitHub](https://github.com/ajeetdsouza/zoxide)
- [FZF GitHub](https://github.com/junegunn/fzf)
- [Eza GitHub](https://github.com/eza-community/eza)
- [Bat GitHub](https://github.com/sharkdp/bat)
