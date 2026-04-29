#!/usr/bin/env bash
# ============================================================================
# Shell Functions - Linux Native (OPTIMIZED)
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
        echo "No suitable editor found" >&2
        return 1
    fi
}

profile-status() {
    printf 'profile=%s\n' "${SHELL_PROFILE:-base}"
    if [ -f "$HOME/.config/shell/profile.local.sh" ]; then
        printf 'persisted=%s\n' "$HOME/.config/shell/profile.local.sh"
    else
        printf 'persisted=none\n'
    fi
    printf 'dotfiles_auto_sync=%s\n' "${DOTFILES_AUTO_SYNC:-0}"
}

switch-profile() {
    local profile_name="${1:-}"
    local profiles_dir="$HOME/.config/shell/profiles"
    local profile_file local_file

    if [ -z "$profile_name" ]; then
        echo "Usage: switch-profile <profile>" >&2
        echo "Available profiles:" >&2
        for profile_file in "$profiles_dir"/*.sh; do
            [ -e "$profile_file" ] || continue
            basename "$profile_file" .sh >&2
        done
        return 1
    fi

    profile_file="$profiles_dir/${profile_name}.sh"
    if [ ! -f "$profile_file" ]; then
        echo "Unknown profile: $profile_name" >&2
        return 1
    fi

    local_file="$HOME/.config/shell/profile.local.sh"
    mkdir -p "$HOME/.config/shell"
    printf 'export SHELL_PROFILE=%q\n' "$profile_name" > "$local_file"
    export SHELL_PROFILE="$profile_name"

    echo "Switched shell profile to: $profile_name"
    exec "${SHELL:-/bin/bash}" -l
}

if [ -n "${BASH_VERSION:-}" ]; then
    _switch_profile_complete() {
        local cur profiles_dir
        cur="${COMP_WORDS[COMP_CWORD]}"
        profiles_dir="$HOME/.config/shell/profiles"

        COMPREPLY=()
        if [ -d "$profiles_dir" ]; then
            while IFS= read -r profile_name; do
                COMPREPLY+=("$profile_name")
            done < <(
                for profile_file in "$profiles_dir"/*.sh; do
                    [ -e "$profile_file" ] || continue
                    basename "$profile_file" .sh
                done | command grep -E "^${cur:-}"
            )
        fi
    }

    complete -F _switch_profile_complete switch-profile
fi

_dotfiles_sync_fetch() {
    local remote="${1:-origin}"
    local dotfiles_dir="$HOME/.dotfiles"
    local -a fetch_cmd=(git -C "$dotfiles_dir" fetch --prune --quiet "$remote")

    if command -v timeout >/dev/null 2>&1; then
        timeout 8 "${fetch_cmd[@]}"
    else
        "${fetch_cmd[@]}"
    fi
}

_dotfiles_sync_run() {
    local mode="${1:-manual}"
    local dotfiles_dir="$HOME/.dotfiles"
    local state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles"
    local stamp_file="$state_dir/last-auto-sync"
    local lock_file="$state_dir/auto-sync.lock"
    local before after upstream remote now last_sync interval

    [[ -d "$dotfiles_dir/.git" ]] || return 0
    mkdir -p "$state_dir"

    if [[ "$mode" == "auto" ]]; then
        [ -t 0 ] && [ -t 1 ] || return 0
        [[ ${DOTFILES_AUTO_SYNC:-0} == 1 ]] || return 0
        [[ -z ${DOTFILES_AUTO_SYNC_RUNNING:-} ]] || return 0

        interval="${DOTFILES_AUTO_SYNC_INTERVAL:-21600}"
        now=$(date +%s)
        last_sync=0
        [ -f "$stamp_file" ] && read -r last_sync < "$stamp_file"
        [[ "$last_sync" =~ ^[0-9]+$ ]] || last_sync=0
        (( now - last_sync >= interval )) || return 0
        [ ! -e "$lock_file" ] || return 0

        printf '%s\n' "$now" > "$lock_file"
        export DOTFILES_AUTO_SYNC_RUNNING=1
    fi

    before=$(git -C "$dotfiles_dir" rev-parse HEAD 2>/dev/null) || {
        rm -f "$lock_file" 2>/dev/null || true
        unset DOTFILES_AUTO_SYNC_RUNNING
        return 1
    }

    if ! git -C "$dotfiles_dir" diff --quiet --ignore-submodules -- 2>/dev/null || \
       ! git -C "$dotfiles_dir" diff --cached --quiet --ignore-submodules -- 2>/dev/null; then
        [[ "$mode" == "manual" ]] && echo "dotfiles-sync: local changes detected in ~/.dotfiles; skipping pull" >&2
        rm -f "$lock_file" 2>/dev/null || true
        unset DOTFILES_AUTO_SYNC_RUNNING
        return 0
    fi

    upstream=$(git -C "$dotfiles_dir" rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null) || {
        [[ "$mode" == "manual" ]] && echo "dotfiles-sync: no upstream configured for ~/.dotfiles" >&2
        rm -f "$lock_file" 2>/dev/null || true
        unset DOTFILES_AUTO_SYNC_RUNNING
        return 0
    }
    remote="${upstream%%/*}"

    if ! GIT_TERMINAL_PROMPT=0 _dotfiles_sync_fetch "$remote"; then
        [[ "$mode" == "manual" ]] && echo "dotfiles-sync: fetch failed" >&2
        rm -f "$lock_file" 2>/dev/null || true
        unset DOTFILES_AUTO_SYNC_RUNNING
        return 1
    fi

    if git -C "$dotfiles_dir" diff --quiet "${upstream}"...HEAD 2>/dev/null && \
       git -C "$dotfiles_dir" diff --quiet HEAD..."${upstream}" 2>/dev/null; then
        [[ "$mode" == "manual" ]] && echo "dotfiles-sync: already up to date"
        printf '%s\n' "$(date +%s)" > "$stamp_file"
        rm -f "$lock_file" 2>/dev/null || true
        unset DOTFILES_AUTO_SYNC_RUNNING
        return 0
    fi

    if ! git -C "$dotfiles_dir" merge --ff-only "$upstream"; then
        [[ "$mode" == "manual" ]] && echo "dotfiles-sync: fast-forward failed" >&2
        rm -f "$lock_file" 2>/dev/null || true
        unset DOTFILES_AUTO_SYNC_RUNNING
        return 1
    fi

    after=$(git -C "$dotfiles_dir" rev-parse HEAD 2>/dev/null)
    printf '%s\n' "$(date +%s)" > "$stamp_file"
    rm -f "$lock_file" 2>/dev/null || true
    unset DOTFILES_AUTO_SYNC_RUNNING

    [[ "$before" != "$after" ]] || return 0

    if [ -f "$dotfiles_dir/Makefile" ]; then
        make -C "$dotfiles_dir" link >/dev/null 2>&1 || true
    fi

    if [[ "$mode" == "auto" ]]; then
        echo "dotfiles-sync: updated from $remote and reloading shell"
    else
        echo "dotfiles-sync: updated from $remote and reloading shell"
    fi
    exec "${SHELL:-/bin/bash}" -l
}

dotfiles-sync() {
    _dotfiles_sync_run manual
}

dotfiles-auto-sync() {
    _dotfiles_sync_run auto
}

claw-status() {
    openclaw gateway status
}

claw-start() {
    openclaw gateway start
}

claw-stop() {
    openclaw gateway stop
}

claw-restart() {
    openclaw gateway restart
}

claw-logs() {
    openclaw channels logs "$@"
}

claw-channels() {
    openclaw channels status --probe
}

# ============================================================================
# Navigation Helpers
# ============================================================================
mkcd() {
    if [ -z "${1:-}" ]; then
        echo "Usage: mkcd <directory>" >&2
        return 1
    fi
    mkdir -p "$1" && cd "$1" || return 1
}

# ============================================================================
# NVM Lazy Loading (significant speed improvement)
# ============================================================================
_load_nvm() {
    export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
    if [ ! -s "$NVM_DIR/nvm.sh" ]; then
        echo "nvm is not installed in $NVM_DIR" >&2
        return 1
    fi

    # shellcheck source=/dev/null
    source "$NVM_DIR/nvm.sh"
    # shellcheck source=/dev/null
    [ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"
}

_load_node_runtime() {
    export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

    if [ -s "$NVM_DIR/nvm.sh" ]; then
        _load_nvm
        return $?
    fi

    # This host currently gets Node from mise. The lazy wrappers below remove
    # themselves before calling this helper, so command lookup sees real shims.
    if command -v node >/dev/null 2>&1 || \
       command -v npm >/dev/null 2>&1 || \
       command -v npx >/dev/null 2>&1; then
        return 0
    fi

    echo "No node runtime found: nvm is not installed in $NVM_DIR and node/npm/npx are not on PATH" >&2
    return 1
}

nvm() {
    unset -f nvm node npm npx 2>/dev/null || true
    _load_nvm || return 1
    nvm "$@"
}

# Lazy load node, npm, npx to trigger NVM loading
node() {
    unset -f node npm npx 2>/dev/null || true
    _load_node_runtime || return 1
    command node "$@"
}

npm() {
    unset -f node npm npx 2>/dev/null || true
    _load_node_runtime || return 1
    command npm "$@"
}

npx() {
    unset -f node npm npx 2>/dev/null || true
    _load_node_runtime || return 1
    command npx "$@"
}

# ============================================================================
# System Update Functions (Multi-distro support)
# ============================================================================
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

# Internal state for upgrade runner
_upgrade_results=()
_upgrade_errors=()
_UPGRADE_STEP_NOTE=""
_UPGRADE_DOTFILES_CHANGED=0

_upgrade_exec_shell() {
    local shell_bin="${SHELL:-/bin/bash}"
    [[ -x "$shell_bin" ]] || shell_bin="/bin/bash"
    exec "$shell_bin" -l
}

_upgrade_fix_cmd() {
    case "$1" in
        system)       echo "yay -Syu --noconfirm  # o tu gestor de distro" ;;
        brew)         echo "brew update && brew upgrade" ;;
        pacdiff)      echo "sudo pacdiff" ;;
        firmware)     echo "fwupdmgr refresh && fwupdmgr update" ;;
        tmux)         echo "~/.tmux/plugins/tpm/bin/update_plugins all" ;;
        hyprpm)       echo "hyprpm update" ;;
        mise)         echo "MISE_SELF_UPDATE=1 mise self-update --yes --no-plugins && mise upgrade" ;;
        pyenv)        echo "cd \${PYENV_ROOT:-\$HOME/.pyenv} && git pull" ;;
        flutter)      echo "flutter upgrade" ;;
        pi)           echo "pi update" ;;
        uv)           echo "uv self update && uv tool upgrade --all" ;;
        pipx)         echo "pipx upgrade-all" ;;
        cargo)        echo "cargo install cargo-update" ;;
        gem)          echo "sudo dnf install ruby-devel && gem update" ;;
        npm)          echo "npm_config_prefix=\$HOME/.npm-global npm update -g" ;;
        yarn)         echo "yarn global upgrade" ;;
        pnpm)         echo "pnpm update -g" ;;
        bun)          echo "bun update -g" ;;
        flatpak)      echo "flatpak update -y" ;;
        tldr)         echo "tldr --update" ;;
        nvim)         echo "nvim --headless '+Lazy! sync' +qa" ;;
        gh)           echo "gh extension upgrade --all" ;;
        gcloud)       echo "gcloud components update --quiet" ;;
        claude)       echo "claude update" ;;
        dotfiles)     echo "cd ~/.dotfiles && git status" ;;
        *)            echo "revisa la salida de arriba" ;;
    esac
}

_upgrade_run_step() {
    local name="$1"
    local fn="$2"
    local start end elapsed elapsed_fmt exit_code note fix_cmd

    start=$(date +%s)
    _UPGRADE_STEP_NOTE=""

    "$fn" && exit_code=0 || exit_code=$?

    end=$(date +%s)
    elapsed=$((end - start))
    elapsed_fmt=$(printf "%dm %02ds" $((elapsed / 60)) $((elapsed % 60)))

    note=""
    [[ -n "$_UPGRADE_STEP_NOTE" ]] && note="  · $_UPGRADE_STEP_NOTE"

    if [[ $exit_code -eq 0 ]]; then
        _upgrade_results+=("  ✅ $(printf '%-14s' "$name")  $elapsed_fmt$note")
    else
        fix_cmd=$(_upgrade_fix_cmd "$name")
        _upgrade_results+=("  ❌ $(printf '%-14s' "$name")  $elapsed_fmt$note")
        _upgrade_errors+=("  $name → $fix_cmd")
    fi
}

_upgrade_uv() {
    command -v uv &>/dev/null || return 0
    uv self update 2>/dev/null || true
    uv tool upgrade --all
}

_upgrade_gem() {
    local gem_bin ruby_bin
    gem_bin=$(type -ap gem 2>/dev/null | grep -v '^/mnt/' | head -1)
    ruby_bin=$(type -ap ruby 2>/dev/null | grep -v '^/mnt/' | head -1)
    [[ -n "$gem_bin" && -n "$ruby_bin" ]] || return 0

    if "$gem_bin" list -i rdoc -v 7.2.0 >/dev/null 2>&1; then
        "$gem_bin" uninstall rdoc -v 7.2.0 -x -I >/dev/null 2>&1 || true
    fi

    local hdrdir
    hdrdir=$("$ruby_bin" -e 'require "rbconfig"; print RbConfig::CONFIG["rubyhdrdir"]' 2>/dev/null)
    if [[ ! -f "${hdrdir}/ruby.h" ]]; then
        _UPGRADE_STEP_NOTE="ruby-devel faltante → sudo dnf install ruby-devel"
        return 1
    fi

    "$gem_bin" update
    local rc=$?

    if "$gem_bin" list -i rdoc -v 7.2.0 >/dev/null 2>&1; then
        "$gem_bin" uninstall rdoc -v 7.2.0 -x -I >/dev/null 2>&1 || true
    fi

    "$gem_bin" cleanup 2>/dev/null || true
    return $rc
}

_upgrade_cargo() {
    command -v cargo &>/dev/null || return 0
    if ! command -v cargo-install-update &>/dev/null; then
        _UPGRADE_STEP_NOTE="cargo-install-update no encontrado — instala con: cargo install cargo-update"
        return 0
    fi
    cargo install-update -a
}

_upgrade_pipx() {
    local pipx_bin
    pipx_bin=$(type -ap pipx 2>/dev/null | grep -v '^/mnt/' | head -1)
    [[ -n "$pipx_bin" ]] || return 0
    (cd "$HOME" && "$pipx_bin" upgrade-all)
}

_upgrade_npm() {
    command -v npm &>/dev/null || return 0
    local npm_prefix="$HOME/.npm-global"
    mkdir -p "$npm_prefix"
    npm_config_prefix="$npm_prefix" npm update -g
}

_upgrade_yarn() {
    command -v yarn &>/dev/null || return 0
    yarn global upgrade
}

_upgrade_pnpm() {
    command -v pnpm &>/dev/null || return 0
    pnpm update -g
}

_upgrade_bun() {
    command -v bun &>/dev/null || return 0
    bun update -g
}

_upgrade_flatpak() {
    command -v flatpak &>/dev/null || return 0
    flatpak update -y
}

_upgrade_mise() {
    command -v mise &>/dev/null || return 0
    if [[ "${MISE_SELF_UPDATE:-0}" == "1" ]]; then
        mise self-update --yes --no-plugins 2>/dev/null || true
    fi
    mise upgrade
}

_upgrade_pyenv() {
    command -v pyenv &>/dev/null || return 0
    local pyenv_root="${PYENV_ROOT:-$HOME/.pyenv}"
    [[ -d "$pyenv_root/.git" ]] || return 0
    git -C "$pyenv_root" pull --rebase --autostash
}

_upgrade_brew() {
    command -v brew &>/dev/null || return 0
    brew update && brew upgrade --formula && brew upgrade --cask
}

_upgrade_pacdiff() {
    command -v pacdiff &>/dev/null || return 0
    sudo --preserve-env=DIFFPROG pacdiff --nobackup
}

_upgrade_fwupdmgr() {
    command -v fwupdmgr &>/dev/null || return 0
    fwupdmgr refresh && fwupdmgr get-updates
}

_upgrade_tmux() {
    local tpm="$HOME/.tmux/plugins/tpm/bin/update_plugins"
    [[ -x "$tpm" ]] || return 0
    "$tpm" all
}

_upgrade_hyprpm() {
    command -v hyprpm &>/dev/null || return 0
    hyprpm update
}

_upgrade_flutter() {
    command -v flutter &>/dev/null || return 0
    flutter upgrade
}

_upgrade_tldr() {
    command -v tldr &>/dev/null || return 0
    tldr --update
}

_upgrade_nvim() {
    command -v nvim &>/dev/null || return 0
    nvim --headless "+Lazy! sync" +qa 2>/dev/null || true
}

_upgrade_gh() {
    command -v gh &>/dev/null || return 0
    gh extension upgrade --all
}

_upgrade_gcloud() {
    command -v gcloud &>/dev/null || return 0
    gcloud components update --quiet
}

_upgrade_claude() {
    command -v claude &>/dev/null || return 0
    claude update && claude plugin marketplace update
}

_upgrade_docker() {
    command -v docker &>/dev/null || return 0
    local images
    images=$(docker image ls --format '{{.Repository}}:{{.Tag}}' 2>/dev/null | grep -v '<none>' || true)
    [[ -n "$images" ]] || return 0
    echo "$images" | xargs -r -n1 docker pull
}

_upgrade_pi() {
    command -v pi &>/dev/null || return 0
    pi update
}

_upgrade_system() {
    local _askpass="" _sudo_pipe
    if [[ -n "${DOTFILES_SUDO_PASS:-}" ]]; then
        _askpass=$(mktemp)
        printf '#!/bin/sh\nprintf "%%s\n" "%s"\n' "$DOTFILES_SUDO_PASS" > "$_askpass"
        chmod 700 "$_askpass"
        _sudo_pipe() { SUDO_ASKPASS="$_askpass" sudo -A "$@"; }
    else
        _sudo_pipe() { sudo "$@"; }
    fi

    local rc=0
    if command -v yay &>/dev/null; then
        yay -Pw 2>/dev/null || true
        if [[ -n "${DOTFILES_SUDO_PASS:-}" ]]; then
            SUDO_ASKPASS="$_askpass" yay -Syu --noconfirm --sudoflags="-A" || rc=$?
        else
            yay -Syu --noconfirm || rc=$?
        fi
    elif command -v paru &>/dev/null; then
        if [[ -n "${DOTFILES_SUDO_PASS:-}" ]]; then
            SUDO_ASKPASS="$_askpass" paru -Syu --noconfirm --sudoflags="-A" || rc=$?
        else
            paru -Syu --noconfirm || rc=$?
        fi
    elif command -v pacman &>/dev/null; then
        _sudo_pipe pacman -Syu --noconfirm || rc=$?
    elif command -v dnf &>/dev/null; then
        _sudo_pipe dnf upgrade -y || rc=$?
    elif command -v apt &>/dev/null; then
        _sudo_pipe apt update && _sudo_pipe apt upgrade -y || rc=$?
    elif command -v zypper &>/dev/null; then
        _sudo_pipe zypper refresh && _sudo_pipe zypper update -y || rc=$?
    elif command -v apk &>/dev/null; then
        _sudo_pipe apk update && _sudo_pipe apk upgrade || rc=$?
    else
        echo "No se reconoce el gestor de paquetes" >&2
        rc=1
    fi

    [[ -n "$_askpass" ]] && rm -f -- "$_askpass"
    unset -f _sudo_pipe
    return $rc
}

_upgrade_dotfiles() {
    local dotfiles_dir="$HOME/.dotfiles"
    [[ -d "$dotfiles_dir/.git" ]] || return 0

    local before after count upstream remote
    before=$(git -C "$dotfiles_dir" rev-parse HEAD 2>/dev/null) || return 1

    if ! git -C "$dotfiles_dir" diff --quiet --ignore-submodules -- 2>/dev/null || \
       ! git -C "$dotfiles_dir" diff --cached --quiet --ignore-submodules -- 2>/dev/null; then
        _UPGRADE_STEP_NOTE="cambios locales en ~/.dotfiles → se omite pull"
        return 0
    fi

    upstream=$(git -C "$dotfiles_dir" rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null) || {
        _UPGRADE_STEP_NOTE="sin upstream configurado en ~/.dotfiles"
        return 0
    }
    remote="${upstream%%/*}"

    git -C "$dotfiles_dir" fetch --prune "$remote" || return 1
    after=$(git -C "$dotfiles_dir" rev-parse HEAD 2>/dev/null)

    if [[ "$before" = "$after" ]]; then
        if git -C "$dotfiles_dir" diff --quiet "${upstream}"...HEAD 2>/dev/null && \
           git -C "$dotfiles_dir" diff --quiet HEAD..."${upstream}" 2>/dev/null; then
            _UPGRADE_STEP_NOTE="ya al día"
            return 0
        fi
    fi

    git -C "$dotfiles_dir" merge --ff-only "${upstream}" || return 1
    after=$(git -C "$dotfiles_dir" rev-parse HEAD 2>/dev/null)

    if [[ "$before" != "$after" ]]; then
        count=$(git -C "$dotfiles_dir" rev-list --count "${before}..${after}" 2>/dev/null)
        _UPGRADE_STEP_NOTE="${count} commit(s) nuevos → reinicio de shell al terminar"
        _UPGRADE_DOTFILES_CHANGED=1
    else
        _UPGRADE_STEP_NOTE="ya al día"
    fi
}

upgrade() {
    _upgrade_results=()
    _upgrade_errors=()
    _UPGRADE_DOTFILES_CHANGED=0

    # Cache sudo credentials once so subcommands don't re-prompt
    sudo -v 2>/dev/null || true

    local -a steps=(
        "system:_upgrade_system"
        "brew:_upgrade_brew"
        "firmware:_upgrade_fwupdmgr"
        "tmux:_upgrade_tmux"
        "hyprpm:_upgrade_hyprpm"
        "mise:_upgrade_mise"
        "pyenv:_upgrade_pyenv"
        "flutter:_upgrade_flutter"
        "pi:_upgrade_pi"
        "uv:_upgrade_uv"
        "pipx:_upgrade_pipx"
        "cargo:_upgrade_cargo"
        "gem:_upgrade_gem"
        "npm:_upgrade_npm"
        "yarn:_upgrade_yarn"
        "pnpm:_upgrade_pnpm"
        "bun:_upgrade_bun"
        "flatpak:_upgrade_flatpak"
        "tldr:_upgrade_tldr"
        "nvim:_upgrade_nvim"
        "gh:_upgrade_gh"
        "gcloud:_upgrade_gcloud"
        "claude:_upgrade_claude"
        "dotfiles:_upgrade_dotfiles"
        "pacdiff:_upgrade_pacdiff"
    )

    local total=${#steps[@]}
    local i=0 name fn

    echo "🔄 Actualizando sistema..."
    echo

    for step in "${steps[@]}"; do
        name="${step%%:*}"
        fn="${step##*:}"
        i=$((i + 1))
        printf "[%d/%d] %s...\n" "$i" "$total" "$name"
        _upgrade_run_step "$name" "$fn"
    done

    local sep="──────────────────────────────────────────"
    echo
    echo "$sep"
    local result
    for result in "${_upgrade_results[@]}"; do
        echo "$result"
    done
    echo

    local failed=${#_upgrade_errors[@]}
    local succeeded=$((total - failed))
    echo "  ${succeeded}/${total} completados · ${failed} fallo(s)"

    if [[ $failed -gt 0 ]]; then
        echo
        local err
        for err in "${_upgrade_errors[@]}"; do
            echo "$err"
        done
    fi
    echo "$sep"

    if [[ $_UPGRADE_DOTFILES_CHANGED -eq 1 ]]; then
        echo
        echo "♻️  Reiniciando shell para aplicar cambios en dotfiles..."
        _upgrade_exec_shell
    fi

    unset _upgrade_results _upgrade_errors _UPGRADE_DOTFILES_CHANGED _UPGRADE_STEP_NOTE
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
    rm -rf ~/.cache/thumbnails/* 2>/dev/null || true
    
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
localip() {
    ip -o -4 addr show scope global | awk '{split($4, cidr, "/"); print cidr[1]}'
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
    if [ -z "${1:-}" ]; then
        echo "Usage: psgrep <pattern>" >&2
        return 1
    fi
    ps aux | command grep -i --color=auto -e VSZ -e "$*"
}

killport() {
    local port="$1"
    if [ -z "$port" ]; then
        echo "Usage: killport <port>" >&2
        return 1
    fi
    local pid
    pid=$(lsof -ti:"$port" 2>/dev/null)
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
    curl -fsSL "https://www.gitignore.io/api/$*"
}

gclonecd() {
    if [ -z "${1:-}" ]; then
        echo "Usage: gclonecd <repo>" >&2
        return 1
    fi
    git clone "$1" && cd "$(basename "$1" .git)" || return 1
}

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
    [[ "$port" =~ ^[0-9]+$ ]] || {
        echo "Usage: serve [port]" >&2
        return 1
    }
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

# Find files by pattern
unalias ff 2>/dev/null
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
        echo "Usage: search <pattern> [path]" >&2
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
        echo "Usage: which_cmd <command>" >&2
        return 1
    fi
    
    type -a "$1"
    if command -v "$1" &>/dev/null; then
        command ls -lh "$(command -v "$1")"
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
    echo "Uptime:         $(uptime -p 2>/dev/null || uptime)"
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
# FZF Advanced Functions
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
    
    # Interactive directory change
    fcd() {
        local dir
        dir=$(find "${1:-.}" -type d 2>/dev/null | fzf +m) && cd "$dir" || return
    }
    
    # Interactive git branch checkout
    fgco() {
        local branch
        branch=$(git branch --all 2>/dev/null | grep -v HEAD | sed 's/^..//' | fzf +m) &&
        git checkout "$(echo "$branch" | sed 's#remotes/[^/]*/##')"
    }
fi

# ============================================================================
# File Hash Utilities
# ============================================================================
sha256() {
    if [ -f "$1" ]; then
        sha256sum "$1" | awk '{print $1}'
    else
        echo "File not found: $1" >&2
        return 1
    fi
}

md5() {
    if [ -f "$1" ]; then
        md5sum "$1" | awk '{print $1}'
    else
        echo "File not found: $1" >&2
        return 1
    fi
}

# ============================================================================
# Directory Shortcuts
# ============================================================================
dirs() {
    if [ $# -eq 0 ]; then
        builtin dirs -v
    else
        find . -type f -name "$1" 2>/dev/null
    fi
}

ports() {
    if command -v ss &>/dev/null; then
        ss -tulanp "$@"
    else
        netstat -tulanp "$@"
    fi
}

dc() {
    if command -v docker-compose &>/dev/null; then
        command docker-compose "$@"
    else
        command docker compose "$@"
    fi
}

# ============================================================================
# Zoxide Integration (lazy - only if available)
# ============================================================================
if command -v zoxide &>/dev/null; then
    alias cd='z'
    alias cdi='zi'
fi
