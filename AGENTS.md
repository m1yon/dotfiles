# Repository Agent Rules

## Declarative system management

- Manage system packages, apps, casks, services, settings, defaults, and behavior through the Nix flake or modules.
- Never install global or system packages imperatively with `brew`, `nix profile`, global language package managers, app installers, or manual downloads.
- Homebrew is allowed only as a nix-darwin/nix-homebrew backend declared in the flake; do not mutate packages with the `brew` CLI.
- Unless explicitly asked, do not change system or app settings through GUIs, `defaults write`, vendor CLIs, or files outside the Nix-managed configuration.
- Project-local dependency commands may update a project's normal dependency state and lockfiles.
  - Allowed: `bun install` inside `scripts/bun/`.
  - Forbidden: `bun add -g`, `npm install -g`, or any other global package installation.

## Agent configuration

- Claude Code and Codex share one global instruction file: `dotfiles/agents/AGENTS.md`. Its `## pstack model configuration` section is the pstack model sheet for both harnesses and for the Codex Cloud bootstrap, so keep that heading and the row format.
- Put Claude-only rules in `dotfiles/claude/CLAUDE.md`, below its imports.
- Put Codex-only rules in a `developer_instructions` key on the Codex config in `system/agents.nix`. Codex has no include syntax, and its `AGENTS.override.md` replaces the shared file instead of adding to it.
- Refer to pstack skills by name in the shared file instead of importing or inlining them, so both harnesses read the version they have installed.
- Edit model rows in the repo. Do not run `/setup-pstack`: it overwrites the sheet, which links to the shared file.
- Both harnesses install pstack from its git marketplace and update it on their own, so don't pin a version.

## Verification

- Use the relevant Nix eval or check as the primary verification for Nix configuration changes.
- Treat warnings as verification failures: fix them and rerun the eval or check until it completes without warnings.
- Agents may stage newly added, imported Nix files when flake evaluation requires it; do not stage unrelated changes.

## Rebuild permissions

- After verification succeeds without warnings, run `task rebuild` on nixbook from the checkout that holds the change. Do not ask Michael first.
- An agent on nixbook has no terminal for the sudo prompt:
  1. Call T3 Code's `request_secret` with `delivery: "file"`.
  2. Run `SUDO_PASSWORD_FILE=<file> task rebuild`.
  3. Delete the file.
- If `task rebuild` needs a terminal, such as on the Mac, ask Michael to run it.
- Do not run any other rebuild, switch, or apply command, including:
  - `darwin-rebuild switch`
  - `nixos-rebuild switch`
  - `home-manager switch`
