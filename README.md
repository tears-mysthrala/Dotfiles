# Linux Native Dotfiles

Modern shell configuration for Linux with automated dependency management.

## 🚀 Quick Start

```bash
# Clone the repository
git clone https://github.com/tears-mysthrala/Dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# Run the installer
chmod +x install.sh
./install.sh
```

The installer will:
1. Detect your Linux distribution
2. Install `make` and `git` if needed
3. Install modern CLI tools (starship, zoxide, fzf, eza, bat)
4. Create symbolic links to shell configuration
5. Configure your `.bashrc` or `.zshrc`

## 📦 What's Included

### Modern CLI Tools
- **[Starship](https://starship.rs/)** - Cross-shell prompt
- **[Zoxide](https://github.com/ajeetdsouza/zoxide)** - Smarter `cd` command
- **[FZF](https://github.com/junegunn/fzf)** - Fuzzy finder
- **[Eza](https://github.com/eza-community/eza)** - Modern `ls` replacement
- **[Bat](https://github.com/sharkdp/bat)** - Cat with syntax highlighting

### Shell Configuration
- **aliases.sh** - Common shortcuts and modern tool aliases
- **functions.sh** - Useful shell functions (system updates, git helpers, etc.)
- **exports.sh** - Environment variables and PATH configuration

## 🛠️ Manual Installation

```bash
# Install dependencies only
make deps

# Create symbolic links only
make link

# Configure shell initialization only
make config

# Full installation
make install
```

## 📋 Available Make Targets

| Target | Description |
|--------|-------------|
| `make install` | Full installation (deps + link + config) |
| `make deps` | Install modern CLI tools |
| `make link` | Create symbolic links |
| `make config` | Configure shell initialization |
| `make clean` | Remove symbolic links |
| `make help` | Show all available targets |

### Individual Tool Installation

```bash
make starship    # Install Starship prompt
make zoxide      # Install Zoxide
make fzf         # Install FZF
make eza         # Install Eza
make bat         # Install Bat
```

## 🐧 Supported Distributions

- **Debian/Ubuntu** (apt)
- **Fedora/RHEL** (dnf/yum)
- **Arch Linux** (pacman)
- **openSUSE** (zypper)
- **Alpine Linux** (apk)

## 🎨 Features

### Smart Aliases
```bash
# Navigation
..          # cd ..
...         # cd ../..
.3          # cd ../../..

# Modern tools
ls          # eza with icons and git integration
ll          # eza long format
la          # eza all files
cat         # bat with syntax highlighting

# Git shortcuts
g           # git
gst         # git status
pull        # git pull
push        # git push
```

### Powerful Functions
```bash
upgrade     # Update all packages (auto-detects package manager)
cleanup     # Clean package cache and temporary files
mkcd        # Create directory and cd into it
extract     # Universal archive extractor
sysinfo     # Display system information
```

### Environment Variables
- Optimized `PATH` with `~/.local/bin`
- FZF with bat preview
- Starship prompt configuration
- Zoxide smart navigation
- Language and locale settings

## 🔧 Customization

### Local Overrides

Create local configuration files that won't be tracked by git:

```bash
# Custom exports
~/.config/shell/exports.local.sh

# Custom aliases
~/.config/shell/aliases.local.sh

# Custom functions
~/.config/shell/functions.local.sh
```

### Starship Configuration

Edit `~/.config/starship.toml` to customize your prompt.

## 🗑️ Uninstallation

```bash
# Remove symbolic links
make clean

# Complete uninstall
make uninstall
```

## 📝 Directory Structure

```
.
├── install.sh              # Bootstrap installer
├── Makefile                # Installation orchestration
├── cleanup-legacy.sh       # Legacy PowerShell cleanup script
├── README.md
└── dotfiles/
    └── shell/
        ├── aliases.sh      # Shell aliases
        ├── functions.sh    # Shell functions
        └── exports.sh      # Environment variables
```

## 🤝 Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details.

## 📄 License

This project is licensed under the MIT License.

## 🙏 Acknowledgments

- Inspired by the modern CLI tools ecosystem
- Built for cross-distribution compatibility
- Ported from a PowerShell configuration

---

**Note:** This is a Linux-native rewrite of a previous PowerShell configuration. All PowerShell-specific code has been replaced with POSIX-compliant shell scripts.
