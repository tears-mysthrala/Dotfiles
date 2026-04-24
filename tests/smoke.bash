#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp_home="$(mktemp -d)"
trap 'rm -rf "$tmp_home"' EXIT
mode="${1:-all}"

export HOME="$tmp_home"
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
unset OMORA_PATH OMARCHY_PATH SHELL_PROFILE DOTFILES_AUTO_SYNC DOTFILES_AUTO_SYNC_RUNNING
export DOTFILES_SKIP_MISE=1

assert_contains() {
    local haystack="$1"
    local needle="$2"
    if [[ "$haystack" != *"$needle"* ]]; then
        printf 'assertion failed: expected to find "%s"\n' "$needle" >&2
        printf 'output was:\n%s\n' "$haystack" >&2
        return 1
    fi
}

setup_home() {
    printf '::group::link-config\n'
    ln -s "$repo_root" "$HOME/.dotfiles"
    make -C "$repo_root" link config
    printf '::endgroup::\n'
}

run_syntax() {
    printf '::group::syntax\n'
    bash -n "$repo_root/dotfiles/bashrc"
    bash -n "$repo_root/dotfiles/bash_profile"
    bash -n "$repo_root/dotfiles/profile"
    bash -n "$repo_root/dotfiles/shell/aliases.sh"
    bash -n "$repo_root/dotfiles/shell/functions.sh"
    bash -n "$repo_root/dotfiles/shell/exports.sh"
    bash -n "$repo_root/dotfiles/shell/profiles/base.sh"
    bash -n "$repo_root/dotfiles/shell/profiles/ctf.sh"
    printf '::endgroup::\n'
}

run_doctor() {
    printf '::group::doctor\n'
    make -C "$repo_root" doctor
    printf '::endgroup::\n'
}

run_profiles() {
    printf '::group::base-profile\n'
    base_output="$(
        SHELL_PROFILE=base bash -ic '
            declare -F profile-status >/dev/null && echo profile_status=yes || echo profile_status=no
            declare -F rsa >/dev/null && echo rsa=yes || echo rsa=no
            complete -p switch-profile
            profile-status
        '
    )"
    printf '%s\n' "$base_output"
    assert_contains "$base_output" 'profile_status=yes'
    assert_contains "$base_output" 'rsa=no'
    assert_contains "$base_output" 'complete -F _switch_profile_complete switch-profile'
    assert_contains "$base_output" 'profile=base'
    printf '::endgroup::\n'

    printf '::group::ctf-profile\n'
    ctf_output="$(
        SHELL_PROFILE=ctf bash -ic '
            declare -F profile-status >/dev/null && echo profile_status=yes || echo profile_status=no
            declare -F rsa >/dev/null && echo rsa=yes || echo rsa=no
            profile-status
        '
    )"
    printf '%s\n' "$ctf_output"
    assert_contains "$ctf_output" 'profile_status=yes'
    assert_contains "$ctf_output" 'rsa=yes'
    assert_contains "$ctf_output" 'profile=ctf'
    printf '::endgroup::\n'

    printf '::group::switch-profile\n'
    SHELL_PROFILE=base bash -ic 'switch-profile ctf >/dev/null 2>&1 || true'
    persisted_selector="$(cat "$HOME/.config/shell/profile.local.sh")"
    printf '%s\n' "$persisted_selector"
    assert_contains "$persisted_selector" 'export SHELL_PROFILE=ctf'
    printf '::endgroup::\n'
}

case "$mode" in
    syntax)
        run_syntax
        ;;
    doctor)
        setup_home
        run_doctor
        ;;
    profiles)
        setup_home
        run_profiles
        ;;
    all)
        setup_home
        run_syntax
        run_doctor
        run_profiles
        ;;
    *)
        printf 'unknown test mode: %s\n' "$mode" >&2
        exit 1
        ;;
esac

printf 'smoke tests passed (%s)\n' "$mode"
