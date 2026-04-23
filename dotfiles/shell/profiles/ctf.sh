#!/usr/bin/env bash
# CTF / audit shell profile.

_run_if_available() {
    local target="$1"
    shift

    if command -v "$target" >/dev/null 2>&1; then
        command "$target" "$@"
    else
        echo "Missing dependency: $target" >&2
        return 127
    fi
}

_run_file_if_available() {
    local target="$1"
    shift

    if [ -x "$target" ] || [ -f "$target" ]; then
        "$target" "$@"
    else
        echo "Missing file: $target" >&2
        return 127
    fi
}

_run_python_module_if_available() {
    local module="$1"
    shift

    if python3 -c "import $module" >/dev/null 2>&1; then
        python3 -m "$module" "$@"
    else
        echo "Missing Python module: $module" >&2
        return 127
    fi
}

rsa() { _run_if_available RsaCtfTool.py "$@"; }
rsa-solve() { _run_if_available RsaCtfTool.py --publickey "$@"; }
factordb() { _run_python_module_if_available factordb "$@"; }
pinit() { _run_if_available pwninit --template-path "$HOME/.config/pwninit-template.py" "$@"; }
check() { _run_if_available checksec --file "$@"; }
gadgets() { _run_if_available ropper --file "$@"; }
og() { _run_if_available one_gadget "$@"; }

modbus-scan() { _run_file_if_available "$HOME/ctf-toolkit/attack/ot-exploits/modbus-scan-async.py" "$@"; }
s7-scan() { _run_file_if_available "$HOME/ctf-toolkit/attack/ot-exploits/s7-scan.sh" "$@"; }
mqtt-scan() { _run_file_if_available "$HOME/ctf-toolkit/attack/ot-exploits/mqtt-scan.sh" "$@"; }

fscan() { _run_if_available rustscan -a "$@"; }
rscan() { _run_if_available rustscan -a "$@"; }

ligolo-proxy() { _run_file_if_available /usr/local/bin/proxy "$@"; }
ligolo-agent() { _run_file_if_available /usr/local/bin/agent "$@"; }
tunnel() { _run_if_available chisel "$@"; }
