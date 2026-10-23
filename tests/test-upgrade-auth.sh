#!/usr/bin/env bash
set -u
repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
source "$repo_dir/dotfiles/shell/functions.sh"
set -e
# Stub every mutating upgrade stage; retain only the behavior under test.
while IFS= read -r fn; do
    [[ $fn =~ ^_upgrade_[a-z_]+$ ]] || continue
    case "$fn" in
        _upgrade_system|_upgrade_fwupdmgr|_upgrade_pacdiff|_upgrade_run_step|_upgrade_fix_cmd|_upgrade_sudo_keepalive_start|_upgrade_sudo_keepalive_stop) ;;
        *) eval "$fn() { return 0; }" ;;
    esac
done < <(compgen -A function)
[[ -r /etc/os-release ]] || { echo "SKIP: Linux fixture required"; exit 77; }
# Simulate Omarchy on any Linux host; never edit the real OS identity.
grep() {
    if [[ ${@: -1} == /etc/os-release && ${1:-} == -Eq ]]; then return 0; fi
    command grep "$@"
}
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT
export UPGRADE_TEST_WORK="$work"
sudo() { printf '%s\n' "$*" >> "$UPGRADE_TEST_WORK/sudo-calls"; }
omarchy() { [[ "$*" == update ]] || return 88; sudo /usr/bin/true; }
fwupdmgr() { [[ "$*" == 'get-updates --json --no-unreported-check' ]] || return 89; printf '%s\n' '{"Devices":[{"Name":"UEFI dbx"}]}'; }
cat > "$work/pacdiff" <<'SH'
#!/bin/sh
[ "$*" = '--output --pacmandb' ] || exit 91
printf '%s\n' /etc/example.conf.pacnew
SH
chmod 700 "$work/pacdiff"
_command_path_no_windows() { [[ "$1" == pacdiff ]] && printf '%s\n' "$UPGRADE_TEST_WORK/pacdiff"; }
upgrade > "$work/success.log"
[[ $(wc -l < "$work/sudo-calls") -eq 1 ]]
grep -q 'firmware pendiente' "$work/success.log"
grep -q 'configuración pendiente' "$work/success.log"
_upgrade_brew() { return 11; }
if upgrade > "$work/failure.log"; then echo 'Expected failure exit status' >&2; exit 1; fi
omarchy() { return 7; }
if _upgrade_system; then exit 1; else [[ $? -eq 7 ]]; fi
printf '%s\n' 'PASS: one authorization, firmware read-only, pacdiff read-only, aggregate failure and system exit propagation.'
