#!/usr/bin/env bash
# ============================================================================
# Shell Aliases - Linux Native (OPTIMIZED v2)
# Compatible with: Bash 4.0+, Zsh 5.0+
# ============================================================================
# OPTIMIZATION: Fast-path detection for common tools, lazy-load for others

# ============================================================================
# Fast Detection - Only check common/fast tools (skips Windows PATH scan)
# ============================================================================
__has_fast() {
    case ":${__FAST_CMDS}:" in
        *:"$1":*) return 0 ;;
        *) return 1 ;;
    esac
}

# Detectar herramientas comunes (rápidas - verificar paths comunes primero)
__FAST_CMDS=""
for cmd in bat eza fd rg npm python3; do
    # Check common paths first (much faster than type -P with Windows PATH)
    if [ -x "$HOME/.local/bin/$cmd" ] || [ -x "/usr/bin/$cmd" ]; then
        __FAST_CMDS="$__FAST_CMDS:$cmd:"
    fi
done

# ============================================================================
# Navigation Shortcuts
# ============================================================================
alias ..='cd ..'
alias ...='cd ../..'
alias .3='cd ../../..'
alias .4='cd ../../../..'
alias .5='cd ../../../../..'

# ============================================================================
# Editor Detection
# ============================================================================
alias v='editor'
alias e='editor'

# ============================================================================
# System Utilities
# ============================================================================
alias c='clear'
alias csl='clear'
alias shutdownnow='sudo shutdown -h now'
alias rebootnow='sudo reboot'

# ============================================================================
# Git Aliases
# ============================================================================
alias g='git'
alias gst='git status'
alias pull='git pull'
alias push='git push'
alias gaa='git add --all'
alias gc='git commit'
alias gco='git checkout'
alias gdiff='git diff'
alias gl='git log --oneline --graph --decorate'

# ============================================================================
# Docker Aliases
# ============================================================================
alias d='docker'

# ============================================================================
# Modern Tool Replacements (Fast detection)
# ============================================================================

# Bat helper
if __has_fast bat; then
    alias bcat='bat --paging=never --style=plain'
    alias catt='bat --paging=always'
fi

# Eza (better ls)
if __has_fast eza; then
    alias ls='eza --icons --git --color=always --group-directories-first'
    alias ll='eza --icons --git --color=always --group-directories-first --long --header'
    alias la='eza --icons --git --color=always --group-directories-first --all'
    alias lt='eza --icons --git --color=always --group-directories-first --long --header --tree --sort=name'
else
    alias ls='ls --color=auto'
    alias ll='ls -lh --color=auto'
    alias la='ls -lAh --color=auto'
fi

# Keep standard tool semantics for compatibility.
alias grep='grep --color=auto'
__has_fast fd && alias fdf='fd'
__has_fast rg && alias rga='rg'

# ============================================================================
# Network Utilities
# ============================================================================
alias pubip='curl -fsSL https://ifconfig.me/ip'
alias myip='curl -fsSL https://ifconfig.me/ip'

# ============================================================================
# System Information
# ============================================================================
alias uptime='uptime -p'

# ============================================================================
# Archive Extraction
# ============================================================================
alias untar='tar -xvf'

# ============================================================================
# Development Tools
# ============================================================================
alias yolo='codex --dangerously-bypass-approvals-and-sandbox'
alias cx='codex --dangerously-bypass-approvals-and-sandbox'
alias cc='claude --dangerously-skip-permissions'

if __has_fast npm; then
    alias ni='npm install'
    alias nid='npm install --save-dev'
    alias nu='npm update'
    alias nr='npm run'
fi

if __has_fast python3; then
    alias py='python3'
    alias pip='python3 -m pip'
fi

# ============================================================================
# Systemd shortcuts
# ============================================================================
alias sctl='sudo systemctl'
alias jctl='sudo journalctl'

# ============================================================================
# Safe operations
# ============================================================================
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# ============================================================================
# Disk usage (lazy-loaded aliases)
# ============================================================================
# These check on first use to avoid slow Windows PATH lookups
df() {
    if type -P duf &>/dev/null; then
        command duf "$@"
    else
        command df -h "$@"
    fi
}

du() {
    if type -P dust &>/dev/null; then
        command dust "$@"
    else
        command du -h "$@"
    fi
}

# ============================================================================
# Process management (lazy-loaded)
# ============================================================================
htop() {
    if type -P btop &>/dev/null; then
        command btop "$@"
    elif type -P htop &>/dev/null; then
        command htop "$@"
    else
        command top "$@"
    fi
}

top() {
    if type -P btop &>/dev/null; then
        command btop "$@"
    elif type -P htop &>/dev/null; then
        command htop "$@"
    else
        command top "$@"
    fi
}

# ============================================================================
# Lazygit (lazy-loaded)
# ============================================================================
lg() {
    if type -P lazygit &>/dev/null; then
        command lazygit "$@"
    else
        echo "lazygit not installed" >&2
        return 1
    fi
}

# ============================================================================
# File Search Helpers
# ============================================================================
alias whichcmd='which_cmd'
alias switch='switch-profile'
alias profile='profile-status'
alias dsync='dotfiles-sync'
alias claw='openclaw'
alias clawstatus='claw-status'
alias clawstart='claw-start'
alias clawstop='claw-stop'
alias clawrestart='claw-restart'
alias clawchannels='claw-channels'
alias clawlogs='claw-logs'

# ============================================================================
# Clipboard integration (lazy-loaded)
# ============================================================================
pbcopy() {
    if type -P xclip &>/dev/null; then
        command xclip -selection clipboard "$@"
    elif type -P wl-copy &>/dev/null; then
        command wl-copy "$@"
    else
        echo "No clipboard tool found (xclip or wl-copy)" >&2
        return 1
    fi
}

pbpaste() {
    if type -P xclip &>/dev/null; then
        command xclip -selection clipboard -o
    elif type -P wl-copy &>/dev/null; then
        command wl-paste
    else
        echo "No clipboard tool found (xclip or wl-copy)" >&2
        return 1
    fi
}

# ============================================================================
# Cleanup
# ============================================================================
unset -f __has_fast 2>/dev/null || true
unset __FAST_CMDS 2>/dev/null || true
