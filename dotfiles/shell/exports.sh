#!/bin/sh
# ============================================================================
# Environment Variables - Linux Native (OPTIMIZED)
# POSIX-friendly environment layer. Interactive Bash/Zsh behavior lives in
# bashrc, zshrc, aliases.sh, functions.sh, and optimized-tools.sh.
# ============================================================================

if [ "${DOTFILES_EXPORTS_LOADED:-0}" = "1" ]; then
    return 0 2>/dev/null || exit 0
fi
export DOTFILES_EXPORTS_LOADED=1

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

# Remove exact duplicate PATH entries while preserving the first occurrence.
_path_dedupe() {
    _path_dedupe_old_path="$PATH"
    _path_dedupe_new_path=""

    while [ -n "$_path_dedupe_old_path" ]; do
        _path_dedupe_entry="${_path_dedupe_old_path%%:*}"
        if [ "$_path_dedupe_old_path" = "$_path_dedupe_entry" ]; then
            _path_dedupe_old_path=""
        else
            _path_dedupe_old_path="${_path_dedupe_old_path#*:}"
        fi

        [ -n "$_path_dedupe_entry" ] || continue

        case ":${_path_dedupe_new_path}:" in
            *:"$_path_dedupe_entry":*) ;;
            *) _path_dedupe_new_path="${_path_dedupe_new_path:+$_path_dedupe_new_path:}$_path_dedupe_entry" ;;
        esac
    done

    PATH="$_path_dedupe_new_path"
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
export LANGUAGE="en_US.UTF-8"

# ============================================================================
# Path Configuration (Consolidated - single assignment)
# ============================================================================
# User binaries
_path_prepend "$HOME/.local/bin"
_path_prepend "$HOME/bin"
_path_prepend "$HOME/.atuin/bin"

# Development tools
_path_prepend "$HOME/.opencode/bin"
_path_prepend "$HOME/.npm-global/bin"
export npm_config_prefix="$HOME/.npm-global"

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
    if [ -n "${ZSH_VERSION:-}" ]; then
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv zsh 2>/dev/null || true)"
    else
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv bash 2>/dev/null || true)"
    fi
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

# OpenClaw / Codex CLI
export OPENCLAW_NO_RESPAWN=1
export NODE_COMPILE_CACHE="${XDG_CACHE_HOME}/openclaw-compile-cache"

if [ ! -d "$NODE_COMPILE_CACHE" ]; then
    mkdir -p "$NODE_COMPILE_CACHE" 2>/dev/null || true
fi

# ============================================================================
# Omora / Omarchy Compatibility
# ============================================================================
if [ -z "$OMORA_PATH" ]; then
    if [ -d "$HOME/.local/share/omora" ]; then
        export OMORA_PATH="$HOME/.local/share/omora"
    elif [ -n "$OMARCHY_PATH" ]; then
        export OMORA_PATH="$OMARCHY_PATH"
    else
        export OMORA_PATH="$HOME/.local/share/omarchy"
    fi
fi
export OMARCHY_PATH="${OMARCHY_PATH:-$OMORA_PATH}"

if [ -d "$OMORA_PATH/bin" ]; then
    _path_prepend "$OMORA_PATH/bin"
fi

# ============================================================================
# Tool Configurations
# ============================================================================

# FZF Configuration (fast path detection)
if [ -x "$HOME/.local/bin/fzf" ] || [ -x "/usr/bin/fzf" ] || command -v fzf >/dev/null 2>&1; then
    # Use fd for file listing if available (check common paths first for speed)
    if command -v fd >/dev/null 2>&1; then
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
        --bind ctrl-u:preview-half-page-up
        --bind ctrl-d:preview-half-page-down
        --bind ctrl-f:preview-page-down
        --bind ctrl-b:preview-page-up
        --bind ctrl-g:preview-top
        --bind ctrl-h:preview-bottom
        --bind alt-w:toggle-preview-wrap
        --bind ctrl-e:toggle-preview
    '
    
    export FZF_CTRL_R_OPTS='--preview-window=hidden'
    export FZF_COMPLETION_OPTS='--preview-window=hidden'

    # Add bat preview only for file/directory pickers. History and completion
    # entries are often not paths, so a global preview causes noisy bat errors.
    if command -v bat >/dev/null 2>&1; then
        export FZF_CTRL_T_OPTS="--preview-window=right:60%:border-left --preview 'bat --style=numbers --color=always --line-range :500 {}'"
    fi
fi

# Bat (better cat) - check common paths first for speed
if [ -x "$HOME/.local/bin/bat" ] || [ -x "/usr/bin/bat" ]; then
    export BAT_THEME="Nord"
    export BAT_STYLE="numbers,changes,header"
fi

# Ripgrep - check common paths first
if [ -x "$HOME/.local/bin/rg" ] || [ -x "/usr/bin/rg" ]; then
    if [ -f "$HOME/.config/ripgrep/ripgreprc" ]; then
        export RIPGREP_CONFIG_PATH="$HOME/.config/ripgrep/ripgreprc"
    else
        unset RIPGREP_CONFIG_PATH
    fi
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
export HISTSIZE=32768
export HISTFILESIZE=32768
export HISTCONTROL=ignoreboth:erasedups
export HISTIGNORE="ls:cd:cd -:pwd:exit:date:* --help"
export HISTTIMEFORMAT="%Y-%m-%d %H:%M:%S "

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
# Keep this interactive-only so scripts that source exports do not spawn agents.
if [ -t 0 ] && command -v ssh-agent >/dev/null 2>&1; then
    SSH_AGENT_ENV="${XDG_RUNTIME_DIR:-/tmp}/ssh-agent-${USER}.env"

    if [ -z "$SSH_AUTH_SOCK" ]; then
        if [ -f "$SSH_AGENT_ENV" ]; then
            # shellcheck source=/dev/null
            . "$SSH_AGENT_ENV" >/dev/null 2>&1
            if [ -z "${SSH_AGENT_PID:-}" ] || ! kill -0 "$SSH_AGENT_PID" 2>/dev/null; then
                rm -f "$SSH_AGENT_ENV"
                ssh-agent -s > "$SSH_AGENT_ENV" 2>/dev/null
                # shellcheck source=/dev/null
                . "$SSH_AGENT_ENV" >/dev/null 2>&1
            fi
        else
            ssh-agent -s > "$SSH_AGENT_ENV" 2>/dev/null
            # shellcheck source=/dev/null
            . "$SSH_AGENT_ENV" >/dev/null 2>&1
        fi
    fi
fi
if [ -t 0 ]; then
    export GPG_TTY
    GPG_TTY=$(tty)
fi

# ============================================================================
# Color Support
# ============================================================================
export CLICOLOR=1
export COLORTERM=truecolor
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# ============================================================================
# Pager
# ============================================================================
if command -v bat >/dev/null 2>&1; then
    export PAGER="bat --plain"
else
    export PAGER="less"
fi

# ============================================================================
# Starship Prompt
# ============================================================================
if command -v starship >/dev/null 2>&1; then
    export STARSHIP_CONFIG="$HOME/.config/starship.toml"
fi

# ============================================================================
# Zoxide
# ============================================================================
if command -v zoxide >/dev/null 2>&1; then
    export _ZO_DATA_DIR="$HOME/.local/share/zoxide"
    export _ZO_ECHO=1
fi

# Normalize PATH after all framework/tool initializers have had a chance to edit it.
_path_dedupe

# ============================================================================
# CTF Performance Optimization
# ============================================================================
# Increase file descriptors for high-speed scanners (RustScan, ZMap)
_dotfiles_ulimit_n=$(ulimit -n 2>/dev/null || printf '0')
case "$_dotfiles_ulimit_n" in
    *[!0-9]*|'') _dotfiles_ulimit_n=0 ;;
esac
if [ "$_dotfiles_ulimit_n" -gt 0 ] && [ "$_dotfiles_ulimit_n" -lt 65535 ]; then
    ulimit -n 65535 2>/dev/null || true
fi

# ============================================================================
# Clean up helper function
# ============================================================================
unset -f _path_prepend 2>/dev/null || true
unset -f _path_dedupe 2>/dev/null || true
unset _path_dedupe_old_path _path_dedupe_new_path _path_dedupe_entry _dotfiles_ulimit_n 2>/dev/null || true
