#!/usr/bin/env bash
# ============================================================================
# Shell Aliases - Linux Native (Ported from PowerShell unified_aliases.ps1)
# Compatible with: Bash 4.0+, Zsh 5.0+
# ============================================================================

# ============================================================================
# Navigation Shortcuts
# ============================================================================
alias ..='cd ..'
alias ...='cd ../..'
alias .3='cd ../../..'
alias .4='cd ../../../..'
alias .5='cd ../../../../..'

# ============================================================================
# Editor Detection (lazy-loaded via function in functions.sh)
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
# glog, ghead, gbr are defined as functions in functions.sh

# ============================================================================
# Docker Aliases
# ============================================================================
alias d='docker'
alias dc='docker-compose'

# ============================================================================
# Modern Tool Replacements (Conditional)
# ============================================================================

# Lazygit
if command -v lazygit &>/dev/null; then
    alias lg='lazygit'
fi

# Bat (better cat)
if command -v bat &>/dev/null; then
    alias cat='bat --paging=never --style=plain'
    alias catt='bat --paging=always'
fi

# Eza (better ls)
if command -v eza &>/dev/null; then
    alias ls='eza --icons --git --color=always --group-directories-first'
    alias ll='eza --icons --git --color=always --group-directories-first --long --header'
    alias la='eza --icons --git --color=always --group-directories-first --all'
    alias lt='eza --icons --git --color=always --group-directories-first --long --header --tree --sort=name'
else
    # Fallback to traditional ls with colors
    alias ls='ls --color=auto'
    alias ll='ls -lh --color=auto'
    alias la='ls -lAh --color=auto'
fi

# Fd (better find)
if command -v fd &>/dev/null; then
    alias find='fd'
fi

# Ripgrep (better grep)
if command -v rg &>/dev/null; then
    alias grep='rg'
else
    alias grep='grep --color=auto'
fi

# ============================================================================
# File Operations
# ============================================================================
alias mkcd='mkdir_and_cd'  # Function defined in functions.sh

# ============================================================================
# Network Utilities
# ============================================================================
alias pubip='curl -s http://ifconfig.me/ip'
alias myip='curl -s http://ifconfig.me/ip'

# ============================================================================
# System Information
# ============================================================================
alias uptime='uptime -p'
alias ports='netstat -tulanp'

# ============================================================================
# Package Manager Shortcuts (Distribution-agnostic)
# ============================================================================
# Defined dynamically in functions.sh based on detected distro

# ============================================================================
# Archive Extraction
# ============================================================================
alias unzip='unzip -q'
alias untar='tar -xvf'

# ============================================================================
# Development Tools
# ============================================================================
# NPM
if command -v npm &>/dev/null; then
    alias ni='npm install'
    alias nid='npm install --save-dev'
    alias nu='npm update'
    alias nr='npm run'
fi

# Python
if command -v python3 &>/dev/null; then
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

# To bypass aliases, use: \rm, \cp, \mv

# ============================================================================
# Disk usage
# ============================================================================
if command -v duf &>/dev/null; then
    alias df='duf'
else
    alias df='df -h'
fi

if command -v dust &>/dev/null; then
    alias du='dust'
else
    alias du='du -h'
fi

# ============================================================================
# Process management
# ============================================================================
if command -v btop &>/dev/null; then
    alias htop='btop'
elif command -v htop &>/dev/null; then
    alias top='htop'
fi

# ============================================================================
# File Search Helpers
# ============================================================================
# ff() and search() functions are available directly from functions.sh
alias whichcmd='which_cmd'  # Use 'whichcmd' to avoid overriding native 'which'

# ============================================================================
# Git Advanced Aliases
# ============================================================================
# glog(), ghead(), and gbr() functions are available directly from functions.sh
# No aliases needed as functions are already in scope

# ============================================================================
# Clipboard integration (X11/Wayland)
# ============================================================================
if command -v xclip &>/dev/null; then
    alias pbcopy='xclip -selection clipboard'
    alias pbpaste='xclip -selection clipboard -o'
elif command -v wl-copy &>/dev/null; then
    alias pbcopy='wl-copy'
    alias pbpaste='wl-paste'
fi

# Atajos para el modo de optimización de recursos
alias ac='class_mode'
alias rc='class_mode_off'
