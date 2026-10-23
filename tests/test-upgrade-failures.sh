#!/usr/bin/env bash
set -u
repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
source "$repo_dir/dotfiles/shell/functions.sh"
set -e

expect_status() {
    local expected=$1 actual
    shift
    if "$@"; then actual=0; else actual=$?; fi
    [[ $actual -eq $expected ]] || { printf 'Expected %s, got %s from %s\n' "$expected" "$actual" "$*" >&2; exit 1; }
}

# All actual mutators are mocked. No downloads, package changes or logins.
mise() { return 1; }
pi() { echo 'network unavailable'; return 42; }
expect_status 42 _upgrade_pi
pi() { echo 'cannot self-update this installation'; return 1; }
expect_status 0 _upgrade_pi
[[ $_UPGRADE_STEP_NOTE == *externamente* ]]

nvim() { return 43; }
expect_status 43 _upgrade_nvim

mise() { [[ $1 == self-update ]] && return 44; echo 'unexpected mise upgrade after self-update failure' >&2; return 98; }
MISE_SELF_UPDATE=1 expect_status 44 _upgrade_mise

pass-cli() { echo 'Local encryption key not found; forcing logout' >&2; return 45; }
expect_status 45 _upgrade_pass_cli
[[ $_UPGRADE_STEP_NOTE == *login* ]]

bun() { echo 'unexpected self-update for package-owned Bun' >&2; return 97; }
pacman() { [[ $1 == -Qqo ]] && return 0; return 96; }
expect_status 0 _upgrade_bun
[[ $_UPGRADE_STEP_NOTE == *pacman* ]]
pacman() { return 1; }
bun() { return 46; }
expect_status 46 _upgrade_bun

# A configured mise Codex must not hide a different standalone installation.
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT
mkdir -p "$work/bin" "$work/managed"
cat > "$work/bin/codex" <<'SH'
#!/bin/sh
[ "$1" = update ] || exit 96
exit 47
SH
chmod 700 "$work/bin/codex"
touch "$work/managed/codex"
PATH="$work/bin:$PATH"
UPGRADE_TEST_MISE_CODEX="$work/managed/codex"
mise() { [[ "$*" == 'which codex' ]] || return 95; printf '%s\n' "$UPGRADE_TEST_MISE_CODEX"; }
expect_status 47 _upgrade_codex
UPGRADE_TEST_MISE_CODEX="$work/bin/codex"
expect_status 0 _upgrade_codex
[[ $_UPGRADE_STEP_NOTE == *mise* ]]

mise() { return 1; }
uv() { [[ "$*" == 'self update' ]] && return 48; return 99; }
expect_status 48 _upgrade_uv
_upgrade_mise_manages() { [[ $1 == uv ]]; }
uv() { [[ "$*" == 'tool upgrade --all' ]] && return 49; return 99; }
expect_status 49 _upgrade_uv

echo 'PASS: updater failures propagate; managed Bun is not self-updated; reauthentication is visible.'
