#!/usr/bin/env bash
# ============================================================================
# Environment Variables - Linux Native (OPTIMIZED)
# Compatible with: Bash 4.0+, Zsh 5.0+
# ============================================================================

# ============================================================================
# Helper Functions
# ============================================================================
# Prepend to PATH only if not already present (avoids duplicates)
_path_prepend() {
    case ":${PATH}:" in
        *:"$1":*) ;;
        *) PATH="$1${PATH:+:$PATH}" ;;
    esac
}

# ============================================================================
# Editor Configuration
# ============================================================================
export EDITOR="nvim"
export VISUAL="nvim"

# Neovim configuration
if [ -n "$DEFAULT_NVIM_CONFIG" ]; then
    export NVIM_APPNAME="$DEFAULT_NVIM_CONFIG"
fi

# ============================================================================
# Language & Locale
# ============================================================================
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
export LANGUAGE="en_US.UTF-8"

# ============================================================================
# Path Configuration (Consolidated - single assignment)
# ============================================================================
# User binaries
_path_prepend "$HOME/.local/bin"
_path_prepend "$HOME/bin"

# Development tools
_path_prepend "$HOME/.opencode/bin"
_path_prepend "$HOME/.npm-global/bin"

# Cargo (Rust)
if [ -d "$HOME/.cargo/bin" ]; then
    _path_prepend "$HOME/.cargo/bin"
fi

# Go
if [ -d "$HOME/go/bin" ]; then
    _path_prepend "$HOME/go/bin"
    export GOPATH="$HOME/go"
fi

# Homebrew (Linuxbrew)
if [ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv bash 2>/dev/null || true)"
fi

# Node Version Manager (lazy-loaded, see functions.sh for nvm function)
export NVM_DIR="$HOME/.nvm"

# Python local packages
if [ -d "$HOME/.local/share/python/bin" ]; then
    _path_prepend "$HOME/.local/share/python/bin"
fi

# ============================================================================
# XDG Base Directory Specification
# ============================================================================
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_STATE_HOME="$HOME/.local/state"

# ============================================================================
# Tool Configurations
# ============================================================================

# FZF Configuration (fast path detection)
if [ -x "$HOME/.local/bin/fzf" ] || [ -x "/usr/bin/fzf" ] || type -P fzf &>/dev/null; then
    # Use fd for file listing if available (check common paths first for speed)
    if [ -x "$HOME/.local/bin/fd" ]; then
        export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
        export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
    fi
    
    # Catppuccin Mocha colors for FZF
    export FZF_DEFAULT_OPTS='
        --color=hl:#f38ba8,fg:#cdd6f4,header:#f38ba8
        --color=info:#cba6f7,pointer:#f5e0dc,marker:#f5e0dc
        --color=fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8
        --color=border:#585b70
        --height 40% 
        --layout=reverse 
        --border 
        --cycle
        --scroll-off=5
        --inline-info
        --preview-window=right:60%:border-left
        --bind ctrl-u:preview-half-page-up
        --bind ctrl-d:preview-half-page-down
        --bind ctrl-f:preview-page-down
        --bind ctrl-b:preview-page-up
        --bind ctrl-g:preview-top
        --bind ctrl-h:preview-bottom
        --bind alt-w:toggle-preview-wrap
        --bind ctrl-e:toggle-preview
    '
    
    # Add bat preview if available (check common paths first)
    if [ -x "$HOME/.local/bin/bat" ]; then
        export FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS --preview 'bat --style=numbers --color=always --line-range :500 {}'"
    fi
fi

# Bat (better cat) - check common paths first for speed
if [ -x "$HOME/.local/bin/bat" ] || [ -x "/usr/bin/bat" ]; then
    export BAT_THEME="Nord"
    export BAT_STYLE="numbers,changes,header"
fi

# Ripgrep - check common paths first
if [ -x "$HOME/.local/bin/rg" ] || [ -x "/usr/bin/rg" ]; then
    export RIPGREP_CONFIG_PATH="$HOME/.config/ripgrep/ripgreprc"
fi

# Less (pager)
export LESS="-R -F -X"
export LESSHISTFILE="-"

# Man pages colors (only if bat is available)
if [ -x "$HOME/.local/bin/bat" ] || [ -x "/usr/bin/bat" ]; then
    export MANPAGER="sh -c 'col -bx | bat -l man -p'"
    export MANROFFOPT="-c"
fi

# ============================================================================
# History Configuration
# ============================================================================
export HISTSIZE=10000
export HISTFILESIZE=20000
export HISTCONTROL=ignoreboth:erasedups
export HISTIGNORE="ls:cd:cd -:pwd:exit:date:* --help"
export HISTTIMEFORMAT="%Y-%m-%d %H:%M:%S "

# ============================================================================
# Shell Options (Bash-only)
# ============================================================================
if [ -n "$BASH_VERSION" ]; then
    # Append to history file, don't overwrite it
    shopt -s histappend 2>/dev/null || true
    # Save multi-line commands as one command
    shopt -s cmdhist 2>/dev/null || true
    # Check window size after each command
    shopt -s checkwinsize 2>/dev/null || true
    # Correct minor errors in cd paths
    shopt -s cdspell 2>/dev/null || true
    # Enable recursive globbing with **
    shopt -s globstar 2>/dev/null || true
    # Case-insensitive globbing
    shopt -s nocaseglob 2>/dev/null || true
fi

# ============================================================================
# Development Tools
# ============================================================================
export NODE_OPTIONS="--max-old-space-size=4096"
export PYTHONDONTWRITEBYTECODE=1
export PYTHONUNBUFFERED=1
export PYTHONIOENCODING="utf-8"
export PIP_REQUIRE_VIRTUALENV=false
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1

# ============================================================================
# SSH Agent (Optimized - singleton pattern)
# ============================================================================
# Use a persistent socket to avoid starting a new agent per shell
SSH_AGENT_ENV="${XDG_RUNTIME_DIR:-/tmp}/ssh-agent-${USER}.env"

if [ -z "$SSH_AUTH_SOCK" ]; then
    if [ -f "$SSH_AGENT_ENV" ]; then
        # shellcheck source=/dev/null
        . "$SSH_AGENT_ENV" >/dev/null 2>&1
        # Verify agent is still alive
        if ! kill -0 "$SSH_AGENT_PID" 2>/dev/null; then
            rm -f "$SSH_AGENT_ENV"
            eval "$(ssh-agent -s)" > "$SSH_AGENT_ENV" 2>/dev/null
        fi
    else
        eval "$(ssh-agent -s)" > "$SSH_AGENT_ENV" 2>/dev/null
    fi
fi
export GPG_TTY=$(tty)

# ============================================================================
# Color Support
# ============================================================================
export CLICOLOR=1
export COLORTERM=truecolor
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# ============================================================================
# Pager
# ============================================================================
if command -v bat &>/dev/null; then
    export PAGER="bat --plain"
else
    export PAGER="less"
fi

# ============================================================================
# Starship Prompt
# ============================================================================
if command -v starship &>/dev/null; then
    export STARSHIP_CONFIG="$HOME/.config/starship.toml"
fi

# ============================================================================
# Zoxide
# ============================================================================
if command -v zoxide &>/dev/null; then
    export _ZO_DATA_DIR="$HOME/.local/share/zoxide"
    export _ZO_ECHO=1
fi

# ============================================================================
# Clean up helper function
# ============================================================================
unset -f _path_prepend 2>/dev/null || true

# ============================================================================
# Custom User Configurations
# ============================================================================
if [ -f "$HOME/.config/shell/exports.local.sh" ]; then
    # shellcheck source=/dev/null
    source "$HOME/.config/shell/exports.local.sh"
fi
