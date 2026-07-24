# Repository Agent Rules

## Declarative system management

- Manage system packages, apps, casks, services, settings, defaults, and behavior through the Nix flake or modules.
- Never install global or system packages imperatively with `brew`, `nix profile`, global language package managers, app installers, or manual downloads.
- Homebrew is allowed only as a nix-darwin/nix-homebrew backend declared in the flake; do not mutate packages with the `brew` CLI.
- Unless explicitly asked, do not change system or app settings through GUIs, `defaults write`, vendor CLIs, or files outside the Nix-managed configuration.
- Project-local dependency commands may update a project's normal dependency state and lockfiles.
  - Allowed: `bun install` inside `scripts/bun/`.
  - Forbidden: `bun add -g`, `npm install -g`, or any other global package installation.

## Verification

- On macOS and Linux, use `task rebuild` as the primary verification for Nix configuration changes.
  - Run standalone Nix eval or check commands only to diagnose a rebuild failure or when Michael explicitly requests one.
- Treat warnings as verification failures: fix them and rerun the relevant command until it completes without warnings.
- Agents may stage newly added, imported Nix files when flake evaluation requires it; do not stage unrelated changes.

## Rebuild permissions

- Run `task rebuild` only after `sudo -n -v` confirms an authenticated global sudo ticket. If it fails, ask Michael to run `sudo -v`; never initiate interactive authentication.
- Do not run direct switch or apply commands.
