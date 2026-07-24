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

- Use the relevant Nix eval or check as the primary verification for Nix configuration changes.
- Treat warnings as verification failures: fix them and rerun the eval or check until it completes without warnings.
- Agents may stage newly added, imported Nix files when flake evaluation requires it; do not stage unrelated changes.

## Rebuild permissions

- Do not run:
  - `task rebuild`
  - `darwin-rebuild switch`
  - `nixos-rebuild switch`
  - `home-manager switch`
  - Any other rebuild, switch, or apply command
- After verification succeeds without warnings, ask Michael to run the appropriate `task rebuild` command.
