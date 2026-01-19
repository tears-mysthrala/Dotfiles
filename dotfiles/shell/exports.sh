#!/usr/bin/env bash
# ============================================================================
# Environment Variables - Linux Native
# Compatible with: Bash 4.0+, Zsh 5.0+
# ============================================================================

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
# Path Configuration
# ============================================================================
# Add user binaries to PATH
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/bin:$PATH"

# Cargo (Rust)
if [ -d "$HOME/.cargo/bin" ]; then
    export PATH="$HOME/.cargo/bin:$PATH"
fi

# Go
if [ -d "$HOME/go/bin" ]; then
    export PATH="$HOME/go/bin:$PATH"
    export GOPATH="$HOME/go"
fi

# Node Version Manager (if installed)
if [ -d "$HOME/.nvm" ]; then
    export NVM_DIR="$HOME/.nvm"
fi

# Python local packages
if [ -d "$HOME/.local/share/python/bin" ]; then
    export PATH="$HOME/.local/share/python/bin:$PATH"
fi

# ============================================================================
# Tool Configurations
# ============================================================================

# FZF Configuration
if command -v fzf &>/dev/null; then
    # Use fd for file listing if available
    if command -v fd &>/dev/null; then
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
    
    # Add bat preview if available
    if command -v bat &>/dev/null; then
        export FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS --preview 'bat --style=numbers --color=always --line-range :500 {}'"
    fi
fi

# Bat (better cat)
if command -v bat &>/dev/null; then
    export BAT_THEME="Nord"
    export BAT_STYLE="numbers,changes,header"
fi

# Ripgrep
if command -v rg &>/dev/null; then
    export RIPGREP_CONFIG_PATH="$HOME/.config/ripgrep/ripgreprc"
fi

# Less (pager)
export LESS="-R -F -X"
export LESSHISTFILE="-"

# Man pages colors
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
export MANROFFOPT="-c"

# ============================================================================
# History Configuration
# ============================================================================
export HISTSIZE=10000
export HISTFILESIZE=20000
export HISTCONTROL=ignoreboth:erasedups
export HISTIGNORE="ls:cd:cd -:pwd:exit:date:* --help"
export HISTTIMEFORMAT="%Y-%m-%d %H:%M:%S "

# Append to history file, don't overwrite it
shopt -s histappend 2>/dev/null || true

# Save multi-line commands as one command
shopt -s cmdhist 2>/dev/null || true

# ============================================================================
# Shell Options (Bash)
# ============================================================================
# Check window size after each command
shopt -s checkwinsize 2>/dev/null || true

# Correct minor errors in cd paths
shopt -s cdspell 2>/dev/null || true

# Enable recursive globbing with **
shopt -s globstar 2>/dev/null || true

# Case-insensitive globbing
shopt -s nocaseglob 2>/dev/null || true

# ============================================================================
# Development Tools
# ============================================================================

# Node.js
export NODE_OPTIONS="--max-old-space-size=4096"

# Python
export PYTHONDONTWRITEBYTECODE=1
export PYTHONUNBUFFERED=1
export PYTHONIOENCODING="utf-8"

# Pip
export PIP_REQUIRE_VIRTUALENV=false

# Docker
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1

# ============================================================================
# XDG Base Directory Specification
# ============================================================================
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_STATE_HOME="$HOME/.local/state"

# ============================================================================
# Application-specific configurations
# ============================================================================

# GPG TTY (for git commit signing)
export GPG_TTY=$(tty)

# SSH Agent
if [ -z "$SSH_AUTH_SOCK" ]; then
    eval "$(ssh-agent -s)" >/dev/null 2>&1
fi

# ============================================================================
# Color Support
# ============================================================================
# Enable colored output
export CLICOLOR=1
export COLORTERM=truecolor

# GCC colored output
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
# Starship Prompt (if installed)
# ============================================================================
if command -v starship &>/dev/null; then
    export STARSHIP_CONFIG="$HOME/.config/starship.toml"
fi

# ============================================================================
# Zoxide (if installed)
# ============================================================================
if command -v zoxide &>/dev/null; then
    export _ZO_DATA_DIR="$HOME/.local/share/zoxide"
    export _ZO_ECHO=1
fi

# ============================================================================
# Custom User Configurations
# ============================================================================
# Load custom exports if they exist
if [ -f "$HOME/.config/shell/exports.local.sh" ]; then
    source "$HOME/.config/shell/exports.local.sh"
fi
