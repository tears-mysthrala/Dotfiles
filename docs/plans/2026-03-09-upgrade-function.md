# upgrade() Function Rewrite — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the current `upgrade()` shell function with a comprehensive multi-distro updater that covers system packages (yay/dnf/apt/etc.), language tools (uv, gem, cargo, pipx, npm), flatpak, and dotfiles — with a clean deferred summary and fix commands on failure.

**Architecture:** A `_upgrade_run_step` runner tracks timing and exit codes while letting each step's output flow naturally to the terminal. Results accumulate in arrays and print as a table at the end. Each tool gets its own `_upgrade_*` function. Known failure modes map to specific fix commands.

**Tech Stack:** Bash 4.0+, existing `~/.dotfiles/dotfiles/shell/functions.sh`

---

## Task 1: Add the runner infrastructure

**Files:**
- Modify: `~/.dotfiles/dotfiles/shell/functions.sh` — replace the `upgrade()` block (lines 97–166)

**Step 1: Verify syntax of current file**

```bash
bash -n ~/.dotfiles/dotfiles/shell/functions.sh
```
Expected: no output (no errors).

**Step 2: Delete the old upgrade() function**

Remove lines 97–166 from `functions.sh` (the `upgrade()` function body). Keep `detect_package_manager()` intact — it's used by `cleanup()`.

**Step 3: Add the runner helpers at the end of the System Update section (after detect_package_manager)**

Paste this block immediately after `detect_package_manager()`:

```bash
# Internal state for upgrade runner
_upgrade_results=()
_upgrade_errors=()
_UPGRADE_STEP_NOTE=""
_UPGRADE_DOTFILES_CHANGED=0

_upgrade_fix_cmd() {
    case "$1" in
        system)       echo "yay -Syu --overwrite '*'  # or your distro equivalent" ;;
        npm\ globals) echo "npm install -g npm@latest" ;;
        gem)          echo "gem update --system && gem update" ;;
        cargo)        echo "cargo install cargo-update" ;;
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

    "$fn"
    exit_code=$?

    end=$(date +%s)
    elapsed=$((end - start))
    elapsed_fmt=$(printf "%dm %02ds" $((elapsed / 60)) $((elapsed % 60)))

    note=""
    [[ -n "$_UPGRADE_STEP_NOTE" ]] && note="  · $_UPGRADE_STEP_NOTE"

    if [[ $exit_code -eq 0 ]]; then
        _upgrade_results+=("  ✅ $(printf '%-14s' "$name")  $elapsed_fmt$note")
    else
        fix_cmd=$(_upgrade_fix_cmd "$name")
        _upgrade_results+=("  ❌ $(printf '%-14s' "$name")  $elapsed_fmt")
        _upgrade_errors+=("  $name → $fix_cmd")
    fi
}
```

**Step 4: Verify syntax**

```bash
bash -n ~/.dotfiles/dotfiles/shell/functions.sh
```
Expected: no output.

**Step 5: Commit**

```bash
cd ~/.dotfiles
git add dotfiles/shell/functions.sh
git commit -m "refactor: replace upgrade() with runner infrastructure"
```

---

## Task 2: Add individual step functions

**Files:**
- Modify: `~/.dotfiles/dotfiles/shell/functions.sh` — add after `_upgrade_run_step`

**Step 1: Add all step functions**

Paste this block after `_upgrade_run_step`:

```bash
_upgrade_system() {
    if command -v yay &>/dev/null; then
        yay -Syu
    elif command -v paru &>/dev/null; then
        paru -Syu
    elif command -v pacman &>/dev/null; then
        sudo pacman -Syu
    elif command -v dnf &>/dev/null; then
        sudo dnf upgrade -y
    elif command -v apt &>/dev/null; then
        sudo apt update && sudo apt upgrade -y
    elif command -v zypper &>/dev/null; then
        sudo zypper refresh && sudo zypper update -y
    elif command -v apk &>/dev/null; then
        sudo apk update && sudo apk upgrade
    else
        echo "No se reconoce el gestor de paquetes" >&2
        return 1
    fi
}

_upgrade_uv() {
    command -v uv &>/dev/null || return 0
    uv tool upgrade --all
}

_upgrade_gem() {
    command -v gem &>/dev/null || return 0
    gem update && gem cleanup
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
    command -v pipx &>/dev/null || return 0
    pipx upgrade-all
}

_upgrade_npm() {
    command -v npm &>/dev/null || return 0
    npm update -g
}

_upgrade_flatpak() {
    command -v flatpak &>/dev/null || return 0
    flatpak update -y
}

_upgrade_dotfiles() {
    local dotfiles_dir="$HOME/.dotfiles"
    [[ -d "$dotfiles_dir/.git" ]] || return 0

    local before after count
    before=$(git -C "$dotfiles_dir" rev-parse HEAD 2>/dev/null) || return 1
    git -C "$dotfiles_dir" pull || return 1
    after=$(git -C "$dotfiles_dir" rev-parse HEAD 2>/dev/null)

    if [[ "$before" != "$after" ]]; then
        count=$(git -C "$dotfiles_dir" rev-list --count "${before}..${after}" 2>/dev/null)
        _UPGRADE_STEP_NOTE="${count} commit(s) nuevos → exec bash al terminar"
        _UPGRADE_DOTFILES_CHANGED=1
    else
        _UPGRADE_STEP_NOTE="ya al día"
    fi
}
```

**Step 2: Verify syntax**

```bash
bash -n ~/.dotfiles/dotfiles/shell/functions.sh
```
Expected: no output.

**Step 3: Spot-test one function in isolation**

```bash
bash -c 'source ~/.dotfiles/dotfiles/shell/functions.sh; _upgrade_uv'
```
Expected: either updates uv tools or exits silently (uv not installed).

**Step 4: Commit**

```bash
cd ~/.dotfiles
git add dotfiles/shell/functions.sh
git commit -m "feat: add individual _upgrade_* step functions"
```

---

## Task 3: Add the upgrade() main function

**Files:**
- Modify: `~/.dotfiles/dotfiles/shell/functions.sh` — add after the step functions

**Step 1: Add upgrade()**

Paste this block after `_upgrade_dotfiles`:

```bash
upgrade() {
    # Reset state
    _upgrade_results=()
    _upgrade_errors=()
    _UPGRADE_DOTFILES_CHANGED=0

    local -a steps=(
        "system:_upgrade_system"
        "uv tools:_upgrade_uv"
        "gem:_upgrade_gem"
        "cargo:_upgrade_cargo"
        "pipx:_upgrade_pipx"
        "npm globals:_upgrade_npm"
        "flatpak:_upgrade_flatpak"
        "dotfiles:_upgrade_dotfiles"
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

    # Deferred summary
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

    # Re-source dotfiles if they changed
    if [[ $_UPGRADE_DOTFILES_CHANGED -eq 1 ]]; then
        echo
        echo "♻️  Reiniciando shell para aplicar cambios en dotfiles..."
        exec bash
    fi

    # Cleanup globals
    unset _upgrade_results _upgrade_errors _UPGRADE_DOTFILES_CHANGED _UPGRADE_STEP_NOTE
}
```

**Step 2: Verify full file syntax**

```bash
bash -n ~/.dotfiles/dotfiles/shell/functions.sh
```
Expected: no output.

**Step 3: Dry-run — verify upgrade() loads without error**

```bash
bash -c 'source ~/.dotfiles/dotfiles/shell/functions.sh; declare -f upgrade' | head -5
```
Expected: prints `upgrade ()` and the first few lines of the function.

**Step 4: Verify _upgrade_system picks the right manager on current machine**

```bash
bash -c '
  source ~/.dotfiles/dotfiles/shell/functions.sh
  if command -v yay &>/dev/null; then echo "OK: usará yay"
  elif command -v dnf &>/dev/null; then echo "OK: usará dnf"
  elif command -v apt &>/dev/null; then echo "OK: usará apt"
  else echo "WARN: gestor no detectado"; fi
'
```
Expected: prints which manager would be used.

**Step 5: Commit**

```bash
cd ~/.dotfiles
git add dotfiles/shell/functions.sh
git commit -m "feat: add upgrade() main function with deferred summary"
```

---

## Task 4: Integration test — run upgrade()

**Step 1: Source and run in current shell**

```bash
source ~/.dotfiles/dotfiles/shell/functions.sh
upgrade
```

**Step 2: Verify output format**

Expected structure:
```
🔄 Actualizando sistema...

[1/8] system...
<yay/pacman/dnf output>
[2/8] uv tools...
...

──────────────────────────────────────────
  ✅ system          Xm XXs
  ✅ uv tools        Xm XXs
  ...
  X/8 completados · Y fallo(s)
──────────────────────────────────────────
```

**Step 3: Verify a skipped step shows ✅ (tools not installed are skipped, not failed)**

If `flatpak` is not installed, its result should NOT appear in the summary at all (the function returns 0 early). Confirm this by checking `_upgrade_results` before the summary prints — or simply read the output and verify no ❌ for missing-but-optional tools.

> Note: If a step is skipped (returns 0 due to tool not installed), it still shows ✅ with 0m 00s. That's correct behavior.

**Step 4: Final commit if any tweaks were needed**

```bash
cd ~/.dotfiles
git add dotfiles/shell/functions.sh
git commit -m "fix: adjust upgrade() output after integration test"
```

---

## Notes

- `detect_package_manager()` is NOT modified — `cleanup()` still uses it
- `_upgrade_cargo` returns success (0) when `cargo-install-update` is absent, with a note — this avoids a false failure since most systems won't have it
- `exec bash` replaces the current shell process cleanly, avoiding alias duplication that `source ~/.bashrc` can cause
- The `_upgrade_*` globals are cleaned up at the end of `upgrade()` — but if `exec bash` fires, cleanup is moot since the shell restarts
