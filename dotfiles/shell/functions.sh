#!/usr/bin/env bash
# ============================================================================
# Shell Functions - Linux Native (Ported from PowerShell modules)
# Compatible with: Bash 4.0+, Zsh 5.0+
# ============================================================================

# ============================================================================
# Editor Detection and Initialization
# ============================================================================
editor() {
    local editors=("nvim" "vim" "vi" "nano" "code" "emacs")
    
    if [ -z "$EDITOR" ]; then
        for ed in "${editors[@]}"; do
            if command -v "$ed" &>/dev/null; then
                export EDITOR="$ed"
                export VISUAL="$ed"
                break
            fi
        done
    fi
    
    if [ -n "$EDITOR" ]; then
        "$EDITOR" "$@"
    else
        echo "No suitable editor found"
        return 1
    fi
}

# ============================================================================
# Navigation Helpers
# ============================================================================
mkdir_and_cd() {
    mkdir -p "$1" && cd "$1" || return 1
}

# ============================================================================
# System Update Functions (Multi-distro support)
# ============================================================================

# Detect package manager
detect_package_manager() {
    if command -v apt &>/dev/null; then
        echo "apt"
    elif command -v dnf &>/dev/null; then
        echo "dnf"
    elif command -v yum &>/dev/null; then
        echo "yum"
    elif command -v pacman &>/dev/null; then
        echo "pacman"
    elif command -v zypper &>/dev/null; then
        echo "zypper"
    elif command -v apk &>/dev/null; then
        echo "apk"
    else
        echo "unknown"
    fi
}

# System update (distribution-agnostic)
upgrade() {
    local pkg_manager
    pkg_manager=$(detect_package_manager)
    
    echo "🔄 Starting system upgrade..."
    echo "Package manager: $pkg_manager"
    
    case "$pkg_manager" in
        apt)
            echo "📦 Updating APT packages..."
            sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y
            ;;
        dnf)
            echo "📦 Updating DNF packages..."
            sudo dnf upgrade -y && sudo dnf autoremove -y
            ;;
        yum)
            echo "📦 Updating YUM packages..."
            sudo yum update -y && sudo yum autoremove -y
            ;;
        pacman)
            echo "📦 Updating Pacman packages..."
            sudo pacman -Syu --noconfirm
            ;;
        zypper)
            echo "📦 Updating Zypper packages..."
            sudo zypper refresh && sudo zypper update -y
            ;;
        apk)
            echo "📦 Updating APK packages..."
            sudo apk update && sudo apk upgrade
            ;;
        *)
            echo "⚠️  Unknown package manager"
            return 1
            ;;
    esac
    
    # Update Flatpak if installed
    if command -v flatpak &>/dev/null; then
        echo "📦 Updating Flatpak packages..."
        flatpak update -y
    fi
    
    # Update Snap if installed
    if command -v snap &>/dev/null; then
        echo "📦 Updating Snap packages..."
        sudo snap refresh
    fi
    
    # Update NPM globals
    if command -v npm &>/dev/null; then
        echo "📦 Updating NPM global packages..."
        npm update -g
    fi
    
    # Update Cargo packages
    if command -v cargo &>/dev/null && command -v cargo-install-update &>/dev/null; then
        echo "📦 Updating Cargo packages..."
        cargo install-update -a
    fi
    
    # Update Pipx packages
    if command -v pipx &>/dev/null; then
        echo "📦 Updating Pipx packages..."
        pipx upgrade-all
    fi
    
    echo "✅ System upgrade completed!"
}

# ============================================================================
# System Cleanup Functions
# ============================================================================
cleanup() {
    echo "🧹 Starting system cleanup..."
    
    local pkg_manager
    pkg_manager=$(detect_package_manager)
    
    case "$pkg_manager" in
        apt)
            echo "🗑️  Cleaning APT cache..."
            sudo apt autoremove -y
            sudo apt clean
            ;;
        dnf)
            echo "🗑️  Cleaning DNF cache..."
            sudo dnf autoremove -y
            sudo dnf clean all
            ;;
        pacman)
            echo "🗑️  Cleaning Pacman cache..."
            sudo pacman -Sc --noconfirm
            if command -v paccache &>/dev/null; then
                paccache -rk 2
            fi
            ;;
        *)
            echo "⚠️  Cleanup not configured for this package manager"
            ;;
    esac
    
    # Clean temporary files
    echo "🗑️  Cleaning temporary files..."
    sudo rm -rf /tmp/*
    rm -rf ~/.cache/thumbnails/*
    
    # Clean journal logs (keep last 3 days)
    if command -v journalctl &>/dev/null; then
        echo "🗑️  Cleaning journal logs..."
        sudo journalctl --vacuum-time=3d
    fi
    
    # Clean Docker if installed
    if command -v docker &>/dev/null; then
        echo "🗑️  Cleaning Docker resources..."
        docker system prune -af --volumes
    fi
    
    echo "✅ Cleanup completed!"
}

# ============================================================================
# Network Utilities
# ============================================================================
get_public_ip() {
    curl -s http://ifconfig.me/ip
}

get_local_ip() {
    ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v 127.0.0.1
}

# ============================================================================
# Archive Extraction (Universal)
# ============================================================================
extract() {
    if [ -f "$1" ]; then
        case "$1" in
            *.tar.bz2)   tar xjf "$1"     ;;
            *.tar.gz)    tar xzf "$1"     ;;
            *.tar.xz)    tar xJf "$1"     ;;
            *.bz2)       bunzip2 "$1"     ;;
            *.rar)       unrar x "$1"     ;;
            *.gz)        gunzip "$1"      ;;
            *.tar)       tar xf "$1"      ;;
            *.tbz2)      tar xjf "$1"     ;;
            *.tgz)       tar xzf "$1"     ;;
            *.zip)       unzip "$1"       ;;
            *.Z)         uncompress "$1"  ;;
            *.7z)        7z x "$1"        ;;
            *)           echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# ============================================================================
# Process Management
# ============================================================================
psgrep() {
    ps aux | grep -v grep | grep -i -e VSZ -e "$@"
}

killport() {
    local port="$1"
    if [ -z "$port" ]; then
        echo "Usage: killport <port>"
        return 1
    fi
    local pid
    pid=$(lsof -ti:"$port")
    if [ -n "$pid" ]; then
        kill -9 "$pid"
        echo "Killed process on port $port (PID: $pid)"
    else
        echo "No process found on port $port"
    fi
}

# ============================================================================
# Git Helpers
# ============================================================================
gitignore() {
    curl -sL "https://www.gitignore.io/api/$*"
}

git_clone_cd() {
    git clone "$1" && cd "$(basename "$1" .git)" || return 1
}

# ============================================================================
# Development Utilities
# ============================================================================
# Create a Python virtual environment and activate it
mkvenv() {
    local venv_name="${1:-.venv}"
    python3 -m venv "$venv_name" && source "$venv_name/bin/activate"
}

# HTTP Server (Python)
serve() {
    local port="${1:-8000}"
    python3 -m http.server "$port"
}

# ============================================================================
# File Search Helpers
# ============================================================================
# Find directory by name
fd_dir() {
    if command -v fd &>/dev/null; then
        fd -t d "$@"
    else
        find . -type d -iname "*$1*"
    fi
}

# ============================================================================
# System Information
# ============================================================================
sysinfo() {
    echo "======================================"
    echo "  System Information"
    echo "======================================"
    echo "Hostname:       $(hostname)"
    echo "OS:             $(uname -o)"
    echo "Kernel:         $(uname -r)"
    echo "Architecture:   $(uname -m)"
    echo "Uptime:         $(uptime -p)"
    if command -v lsb_release &>/dev/null; then
        echo "Distribution:   $(lsb_release -d | cut -f2)"
    fi
    echo "======================================"
}

# ============================================================================
# Benchmark Command Execution
# ============================================================================
benchmark() {
    local iterations="${2:-10}"
    echo "Running '$1' $iterations times..."
    time for i in $(seq 1 "$iterations"); do
        eval "$1" > /dev/null 2>&1
    done
}

# ============================================================================
# Zoxide Integration (if available)
# ============================================================================
if command -v zoxide &>/dev/null; then
    alias cd='z'
    alias cdi='zi'
fi

# ============================================================================
# FZF Helpers (if available)
# ============================================================================
if command -v fzf &>/dev/null; then
    # Interactive file search with preview
    fzf_preview() {
        if command -v bat &>/dev/null; then
            fzf --preview 'bat --color=always --style=numbers --line-range=:500 {}'
        else
            fzf --preview 'cat {}'
        fi
    }
    
    # Interactive directory change
    fcd() {
        local dir
        dir=$(find "${1:-.}" -type d 2>/dev/null | fzf +m) && cd "$dir" || return
    }
    
    # Interactive git branch checkout
    fgco() {
        local branch
        branch=$(git branch --all | grep -v HEAD | sed 's/^..//' | fzf +m) &&
        git checkout "$(echo "$branch" | sed 's#remotes/[^/]*/##')"
    }
fi

# ============================================================================
# Chezmoi Helpers (if installed)
# ============================================================================
if command -v chezmoi &>/dev/null; then
    alias cza='chezmoi add'
    alias cze='chezmoi edit'
    alias czd='chezmoi diff'
    alias czap='chezmoi apply'
    czcd() { cd "$(chezmoi source-path)" || return 1; }
    alias cm='chezmoi'
    
    # Chezmoi commit and push
    cmc() {
        local msg="$*"
        if [ -n "$msg" ]; then
            chezmoi git commit -m "$msg"
        else
            chezmoi git commit
        fi
        if [ $? -eq 0 ]; then
            chezmoi git push
        fi
    }
    
    # Chezmoi add from current directory
    cma() {
        local current_dir="$PWD"
        local files=()
        for file in "$@"; do
            files+=("$current_dir/$file")
        done
        cd ~ || return
        chezmoi add "${files[@]}"
        cd "$current_dir" || return
    }
    
    # Chezmoi sync
    cms() {
        local current_dir="$PWD"
        cd ~ || return
        
        # Start gpg-agent if not running
        if ! pgrep -x gpg-agent >/dev/null 2>&1; then
            gpg-connect-agent /bye >/dev/null 2>&1
        fi
        
        chezmoi re-add
        cd "$(chezmoi source-path)" || return
        git status
        cd "$current_dir" || return
    }
fi

# ============================================================================
# File Hash Utilities
# ============================================================================
sha256() {
    if [ -f "$1" ]; then
        sha256sum "$1" | awk '{print $1}'
    else
        echo "File not found: $1"
        return 1
    fi
}

md5() {
    if [ -f "$1" ]; then
        md5sum "$1" | awk '{print $1}'
    else
        echo "File not found: $1"
        return 1
    fi
}

# ============================================================================
# Git Pretty Log (Ported from gitHelpers.ps1)
# ============================================================================
if command -v git &>/dev/null; then
    # Colors for git log
    export GIT_LOG_YELLOW="#F9E2AF"
    export GIT_LOG_RED="#f38ba8"
    export GIT_LOG_BLUE="#89B4FA"
    export GIT_LOG_GREEN="#A6E3A1"
    
    # Pretty git log
    glog() {
        git log --graph --pretty=format:"%C(yellow)%h%Creset %C(green)(%ar)%Creset %C(green)%as%Creset %C(blue)<%an>%Creset%C(red)%d%Creset - %s" --no-show-signature "$@"
    }
    
    # Show git head
    ghead() {
        git log --graph --pretty=format:"%C(yellow)%h%Creset %C(green)(%ar)%Creset %C(blue)<%an>%Creset%C(red)%d%Creset - %s" --no-show-signature -1
        git show -p --pretty="tformat:"
    }
    
    # Pretty git branch
    gbr() {
        git branch -v --color=always --sort=-committerdate "$@"
    }
fi

# ============================================================================
# Advanced File Search (Ported from SearchUtils.ps1)
# ============================================================================

# Find files by pattern
ff() {
    local pattern="${1:-*}"
    local path="${2:-.}"
    local depth="${3:-3}"
    
    if command -v fd &>/dev/null; then
        fd --type f --max-depth "$depth" "$pattern" "$path"
    else
        find "$path" -maxdepth "$depth" -type f -name "$pattern" 2>/dev/null
    fi
}

# Search file content
search() {
    local pattern="$1"
    local path="${2:-.}"
    
    if [ -z "$pattern" ]; then
        echo "Usage: search <pattern> [path]"
        return 1
    fi
    
    if command -v rg &>/dev/null; then
        rg --line-number --column --color=always "$pattern" "$path"
    else
        grep -rn --color=always "$pattern" "$path"
    fi
}

# Which command - find command location
which_cmd() {
    if [ -z "$1" ]; then
        echo "Usage: which_cmd <command>"
        return 1
    fi
    
    type -a "$1"
    if command -v "$1" &>/dev/null; then
        ls -lh "$(command -v "$1")"
    fi
}

# ============================================================================
# Directory Shortcuts (Ported from linuxLike.ps1)
# ============================================================================
dirs() {
    if [ $# -eq 0 ]; then
        find . -type f 2>/dev/null
    else
        find . -type f -name "$1" 2>/dev/null
    fi
}

# ============================================================================
# FZF Advanced Functions (if available)
# ============================================================================
if command -v fzf &>/dev/null; then
    # FZF with ripgrep integration
    fzf_rg() {
        local initial_query="${*:-}"
        local rg_prefix="rg --column --line-number --no-heading --color=always --smart-case"
        
        FZF_DEFAULT_COMMAND="$rg_prefix '$initial_query'" \
        fzf --ansi \
            --disabled \
            --query "$initial_query" \
            --bind "change:reload:$rg_prefix {q} || true" \
            --delimiter ':' \
            --preview 'bat --color=always {1} --highlight-line {2}' \
            --preview-window 'up,60%,border-bottom,+{2}+3/3'
    }
    
    # FZF file finder with preview
    fzf_find() {
        if command -v fd &>/dev/null && command -v bat &>/dev/null; then
            fd --type file --follow --hidden --exclude .git | \
            fzf --preview 'bat --color=always --style=plain {}'
        else
            find . -type f 2>/dev/null | \
            fzf --preview 'cat {}'
        fi
    }
    
    # Open file with fzf selection
    fzf_open() {
        local file
        file=$(fzf_find)
        if [ -n "$file" ]; then
            ${EDITOR:-vim} "$file"
        fi
    }
    
    alias fo='fzf_open'
fi
