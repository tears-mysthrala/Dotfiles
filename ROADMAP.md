# Roadmap — Dotfiles

Last reviewed: 2026-07-28

## Purpose

Personal Linux dotfiles: a portable POSIX login environment plus Bash/Zsh
interactive configuration (aliases, functions, switchable profiles) that works
standalone and layers on top of [omora](https://github.com/tears-mysthrala/omora)
when present. Windows is handled separately by
[PowerShell-profile](https://github.com/tears-mysthrala/PowerShell-profile).

## Users

- The owner, across multiple Linux machines (primary: Fedora workstation).
- Occasional readers looking for shell-config ideas; the repo is public but
  optimized for one maintainer, not for general consumption.

## Current state (observed 2026-07-28)

- POSIX `install.sh` bootstrap with distro/package-manager detection; `Makefile`
  orchestrates `deps` / `link` / `config` / `doctor` / `lint` / `test`.
- `make link`/`config` back up pre-existing files to
  `~/.dotfiles-backup/<timestamp>/` before replacing them; `install.sh
  --dry-run` previews everything without changes.
- CI (`.github/workflows/shell-ci.yml`) passes on `main`: shellcheck, syntax
  checks, doctor, and profile smoke tests on `ubuntu-latest`.
- Switchable profiles (`base`, `ctf`) with a persisted selector; optional
  auto-sync of `~/.dotfiles` on shell startup.
- Local override pattern documented and git-ignored (`*.local.sh`,
  `~/.bashrc.local`, `~/.zshrc.local`).

## Known real problems

- Only Ubuntu is exercised in CI; the Fedora/RHEL, Arch, openSUSE, and Alpine
  paths in `install.sh`/`upgrade()` are detected but not continuously tested.
- Installation is all-or-nothing: there is no way to install only the shell
  layer without the tool downloads, or only a subset of the symlinks.
- No `LICENSE` file; license choice is a pending owner decision.
- Backup directories under `~/.dotfiles-backup/` accumulate forever; no
  pruning or documented restore procedure.
- Tool installation pipes remote install scripts into shells
  (`curl ... | sh`) as a fallback when `cargo` is absent; no checksum
  verification.

## Goal for the next version

Make the installer modular and verifiable: install selected components only,
and prove the non-Ubuntu distro paths in containers.

## Now

- [x] Honest README: explicit scope vs. omora and PowerShell-profile, real
      shell/distro support table, exact list of files the installer modifies.
- [x] Non-destructive installer: timestamped backups before linking, plus
      `install.sh --dry-run`.
- [x] Public defaults vs. machine-local overrides separated, ignored, and
      documented.
- [ ] Owner decision: pick a license and commit a `LICENSE` file.

## Next

- [ ] Module selection in the installer (e.g. `make link-shell`,
      `make link-prompt`, or `./install.sh --only shell,git`) so a minimal
      server can take the shell layer without GUI-adjacent tooling.
- [ ] Container-based install tests (Fedora, Arch, Alpine images) running
      `install.sh --dry-run` plus `make link config doctor` in CI.
- [ ] Document the backup/restore flow: how to recover a file from
      `~/.dotfiles-backup/<timestamp>/`, and a pruning policy or helper.
- [ ] Record per-distro compatibility in the README based on the container
      test results instead of inference.

## Optional

- [ ] Evaluate GNU Stow (or a similarly standard tool) as the linking backend
      if the pair list in the Makefile keeps growing.
- [ ] New-machine bootstrap script that clones, installs, and applies the
      owner's preferred local-override template in one command.
- [ ] Workstation vs. server profiles beyond the current `base`/`ctf` split
      (e.g. a `server` profile with no prompt tooling assumptions).
- [ ] Checksum/signature verification for downloaded tool binaries.

## Out of scope

- Building or maintaining a Linux distribution or installer ISO.
- Graphical/desktop environment configuration (that belongs to omora).
- Duplicating omora or PowerShell-profile functionality here.
- Windows support of any kind in this repository.

## Archive/abandonment condition

Archive this repository if the owner consolidates shell configuration into a
single dotfiles manager (e.g. chezmoi or Stow in another repo) or into omora
itself, leaving no reason to keep a separate Linux dotfiles tree.

## Risks and dependencies

- Depends on upstream install scripts (starship, zoxide, fzf, eza, bat)
  remaining available and compatible with the pinned invocation flags.
- Container tests depend on public base images staying pullable in CI.
- The omora integration depends on `OMORA_PATH` layout staying stable; changes
  there require coordinated updates here.
