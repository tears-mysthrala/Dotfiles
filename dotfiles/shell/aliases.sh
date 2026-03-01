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
alias e='${VISUAL:-${EDITOR:-nano}}'

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
alias gd='git diff'
alias gl='git log --oneline --graph --decorate'

# ============================================================================
# Docker Aliases
# ============================================================================
alias d='docker'
alias dc='docker-compose'

# ============================================================================
# Modern Tool Replacements (Fast detection)
# ============================================================================

# Bat (better cat)
if __has_fast bat; then
    alias cat='bat --paging=never --style=plain'
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

# Fd (better find)
__has_fast fd && alias find='fd'

# Ripgrep (better grep)
if __has_fast rg; then
    alias grep='rg'
else
    alias grep='grep --color=auto'
fi

# ============================================================================
# File Operations
# ============================================================================
alias mkcd='mkdir_and_cd'

# ============================================================================
# Network Utilities
# ============================================================================
alias pubip='curl -s http://ifconfig.me/ip'
alias myip='curl -s http://ifconfig.me/ip'

# ============================================================================
# System Information
# ============================================================================
alias uptime='uptime -p'
alias ports='netstat -tulanp 2>/dev/null || ss -tulanp'

# ============================================================================
# Archive Extraction
# ============================================================================
alias unzip='unzip -q'
alias untar='tar -xvf'

# ============================================================================
# Development Tools
# ============================================================================
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
    unalias df 2>/dev/null || true
    if type -P duf &>/dev/null; then
        alias df='duf'
    else
        alias df='df -h'
    fi
    df "$@"
}

du() {
    unalias du 2>/dev/null || true
    if type -P dust &>/dev/null; then
        alias du='dust'
    else
        alias du='du -h'
    fi
    du "$@"
}

# ============================================================================
# Process management (lazy-loaded)
# ============================================================================
htop() {
    unalias htop top 2>/dev/null || true
    unset -f htop top 2>/dev/null || true
    if type -P btop &>/dev/null; then
        alias htop='btop'
    elif type -P htop &>/dev/null; then
        alias top='htop'
    fi
    htop "$@"
}

top() {
    unalias top htop 2>/dev/null || true
    unset -f top htop 2>/dev/null || true
    if type -P btop &>/dev/null; then
        alias htop='btop'
        btop "$@"
    elif type -P htop &>/dev/null; then
        alias top='htop'
        htop "$@"
    else
        command top "$@"
    fi
}

# ============================================================================
# Lazygit (lazy-loaded)
# ============================================================================
lg() {
    unset -f lg 2>/dev/null || true
    if type -P lazygit &>/dev/null; then
        alias lg='lazygit'
        lazygit "$@"
    else
        echo "lazygit not installed" >&2
        return 1
    fi
}

# ============================================================================
# File Search Helpers
# ============================================================================
alias whichcmd='which_cmd'

# ============================================================================
# Clipboard integration (lazy-loaded)
# ============================================================================
pbcopy() {
    unset -f pbcopy pbpaste 2>/dev/null || true
    if type -P xclip &>/dev/null; then
        alias pbcopy='xclip -selection clipboard'
        alias pbpaste='xclip -selection clipboard -o'
        xclip -selection clipboard "$@"
    elif type -P wl-copy &>/dev/null; then
        alias pbcopy='wl-copy'
        alias pbpaste='wl-paste'
        wl-copy "$@"
    else
        echo "No clipboard tool found (xclip or wl-copy)" >&2
        return 1
    fi
}

pbpaste() {
    unset -f pbcopy pbpaste 2>/dev/null || true
    if type -P xclip &>/dev/null; then
        alias pbcopy='xclip -selection clipboard'
        alias pbpaste='xclip -selection clipboard -o'
        xclip -selection clipboard -o
    elif type -P wl-copy &>/dev/null; then
        alias pbcopy='wl-copy'
        alias pbpaste='wl-paste'
        wl-paste
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
