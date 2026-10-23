# Upgrade ownership and external applications

`upgrade` keeps Omarchy in charge of system packages and its authorization lifecycle.
Runtime ownership is checked against the command actually selected by `PATH`: a
standalone Codex is updated independently even when another Codex exists in mise.
Mise-owned uv, pi and Claude runtimes are left to mise; their separately managed
tools or plugin marketplaces still have their own stages. Package-owned Bun is
left to the system package stage.

Native updater errors propagate to the final exit status, including failed
self-updates, Neovim execution and Proton Pass reauthentication requirements.
The optional `external-apps` stage invokes `laptop-external-check` when installed.
That helper only checks official release metadata/checksums and inventories local
AppImages; it does not replace binaries or interrupt an active T3 session.
Docker images are not pulled globally by this runner; update each lab with its
compatible recipe and data-migration checks.

Focused checks (stubbed commands; no package updates or login):

```bash
bash tests/test-upgrade-auth.sh
bash tests/test-upgrade-failures.sh
```
