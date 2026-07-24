# Repository Agent Rules

## Nix-only system management

- This is a pure Nix system. Never install global or system packages through an imperative path, including:
  - `brew`
  - `nix profile`
  - Global language-specific package managers
  - App installers
  - Manual downloads
- Homebrew is allowed only as a nix-darwin/nix-homebrew backend declared in the flake.
  - Do not call the `brew` CLI to install, remove, upgrade, or otherwise mutate packages.
- Project-local dependency commands are allowed when they:
  - Operate inside a repository project.
  - Update that project's normal dependency state or lockfiles.
- Examples:
  - Allowed: `bun install` inside `scripts/bun/`.
  - Forbidden: `bun add -g`, `npm install -g`, or any other global language-package installation.

## Declarative configuration

- Manage packages, settings, services, apps, casks, defaults, and system behavior through the Nix flake or modules only.
- Do not change system or app settings through the following unless explicitly asked:
  - GUIs
  - `defaults write`
  - Direct mutation of configuration files outside the Nix-managed files
  - Vendor CLIs

## Verification

- On macOS and Linux, use `task rebuild` as the primary verification for Nix configuration changes.
  - Do not run a separate Nix eval or check first.
  - Run standalone Nix eval or check commands only when diagnosing a rebuild failure or when Michael explicitly requests one.
- Treat every warning from a rebuild, Nix eval, or Nix check as a failed verification.
  - Fix every warning.
  - Rerun the relevant verification command until it completes without warnings.
  - Do not report success while warnings remain.
- Agents may stage newly added Nix files when flake evaluation needs to see imported paths.
  - Do not stage unrelated changes.

## Rebuild permissions

- An agent may run `task rebuild` only after `sudo -n -v` confirms that Michael has already authenticated a global sudo ticket.
- The agent must not initiate interactive sudo authentication.
- If no authenticated sudo ticket is available, ask Michael to run `sudo -v`.
- Do not run direct switch or apply commands.
