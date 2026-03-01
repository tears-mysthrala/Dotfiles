#!/bin/sh
# ============================================================================
# Bootstrap Installation Script for Dotfiles
# POSIX-compliant shell script (no Bash/Zsh required)
# Detects distribution and installs Make + Git if needed
# ============================================================================

set -e  # Exit on error

# Colors for output (POSIX-compatible)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
print_info() {
    printf "${BLUE}[INFO]${NC} %s\n" "$1"
}

print_success() {
    printf "${GREEN}[✓]${NC} %s\n" "$1"
}

print_warning() {
    printf "${YELLOW}[!]${NC} %s\n" "$1"
}

print_error() {
    printf "${RED}[✗]${NC} %s\n" "$1"
}

# Detect distribution
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    elif [ -f /etc/lsb-release ]; then
        . /etc/lsb-release
        echo "$DISTRIB_ID" | tr '[:upper:]' '[:lower:]'
    elif [ -f /etc/debian_version ]; then
        echo "debian"
    elif [ -f /etc/redhat-release ]; then
        echo "rhel"
    else
        echo "unknown"
    fi
}

# Detect package manager
detect_package_manager() {
    if command -v apt >/dev/null 2>&1; then
        echo "apt"
    elif command -v dnf >/dev/null 2>&1; then
        echo "dnf"
    elif command -v yum >/dev/null 2>&1; then
        echo "yum"
    elif command -v pacman >/dev/null 2>&1; then
        echo "pacman"
    elif command -v zypper >/dev/null 2>&1; then
        echo "zypper"
    elif command -v apk >/dev/null 2>&1; then
        echo "apk"
    else
        echo "unknown"
    fi
}

# Check if running as root
check_root() {
    if [ "$(id -u)" -eq 0 ]; then
        SUDO=""
    else
        SUDO="sudo"
    fi
}

# Install dependencies based on package manager
install_deps() {
    local pkg_manager="$1"
    
    print_info "Installing make and git..."
    
    case "$pkg_manager" in
        apt)
            $SUDO apt update
            $SUDO apt install -y make git curl
            ;;
        dnf)
            $SUDO dnf install -y make git curl
            ;;
        yum)
            $SUDO yum install -y make git curl
            ;;
        pacman)
            $SUDO pacman -Sy --noconfirm make git curl
            ;;
        zypper)
            $SUDO zypper install -y make git curl
            ;;
        apk)
            $SUDO apk add --no-cache make git curl
            ;;
        *)
            print_error "Unknown package manager. Please install 'make' and 'git' manually."
            exit 1
            ;;
    esac
}

# Main installation function
main() {
    printf "\n"
    print_info "╔═══════════════════════════════════════════╗"
    print_info "║   Dotfiles Bootstrap Installation         ║"
    print_info "╚═══════════════════════════════════════════╝"
    printf "\n"
    
    # Detect system
    DISTRO=$(detect_distro)
    PKG_MANAGER=$(detect_package_manager)
    check_root
    
    print_info "Detected distribution: $DISTRO"
    print_info "Detected package manager: $PKG_MANAGER"
    
    # Check if make is installed
    if ! command -v make >/dev/null 2>&1; then
        print_warning "Make is not installed"
        install_deps "$PKG_MANAGER"
    else
        print_success "Make is already installed"
    fi
    
    # Check if git is installed
    if ! command -v git >/dev/null 2>&1; then
        print_warning "Git is not installed"
        install_deps "$PKG_MANAGER"
    else
        print_success "Git is already installed"
    fi
    
    # Check if curl is installed
    if ! command -v curl >/dev/null 2>&1; then
        print_warning "Curl is not installed"
        install_deps "$PKG_MANAGER"
    else
        print_success "Curl is already installed"
    fi
    
    printf "\n"
    print_success "Bootstrap dependencies installed successfully!"
    printf "\n"
    
    # Run make install
    print_info "Running 'make install'..."
    if [ -f "./Makefile" ]; then
        make install
    else
        print_error "Makefile not found in current directory"
        exit 1
    fi
    
    printf "\n"
    print_success "╔═══════════════════════════════════════════╗"
    print_success "║   Installation completed successfully!    ║"
    print_success "╚═══════════════════════════════════════════╝"
    printf "\n"
    print_info "Please restart your shell or run:"
    print_info "  source ~/.bashrc   (for Bash)"
    print_info "  source ~/.zshrc    (for Zsh)"
    printf "\n"
}

# Run main function
main "$@"
