# Repository Agent Rules

## Rules and what enforces them

This table pairs each rule with what enforces it. Run `/pstack:correct` when the same correction comes up again, so it fixes the class and updates this table.

| Rule | Enforced by |
| --- | --- |
| Verify every change with `task check`. Any evaluation warning fails it. | `task check` builds `checks.<system>.all` with `--option abort-on-warn true`. That evaluates both hosts and both Home Manager outputs and runs every flake check. CI runs `task check` on every PR. |
| Install packages and set macOS defaults through Nix, never by hand. | The `agent-guard` PreToolUse hook (`system/agent-guard.sh`) in the Claude Code managed settings and the Codex `requirements.toml` blocks brew changes, global npm, pnpm, yarn and bun installs, `nix profile`, `nix-env` and `defaults write`. `checks.agent-guard` tests it. GUIs, app installers and vendor CLIs are covered by these docs only. |
| Stop a process by its PID, never by a name pattern. | The `agent-guard` hook blocks `pkill` and `killall`, because a pattern also matches processes the agent did not start. `checks.agent-guard` tests it. |
| Nix owns T3 Code's background service, `t3code.service`. | The `agent-guard` hook blocks `t3 up`, `t3 service install` and `t3 service uninstall`, which replace or remove that unit. `checks.agent-guard` tests it. |
| Files that tools write at runtime stay out of the repo. | `~/.claude/skills` holds one link per skill (`home/shared/programs/agents.nix`), so Claude Code's own folders stay in `$HOME`. The global git ignores (`home/shared/programs/git.nix`) cover `.DS_Store` and `.claude/settings.local.json`. |
| Tools with their own updater are bootstrapped by Nix and never pinned. | These docs only. |
| The shared instruction file keeps its `## pstack model configuration` heading and row format. | These docs only. |

## Declarative system management

- Manage system packages, apps, casks, services, settings, defaults, and behavior through the Nix flake or modules.
- Homebrew is allowed only as the nix-darwin/nix-homebrew backend declared in `darwin/homebrew.nix`.
- Unless explicitly asked, do not change system or app settings through GUIs, vendor CLIs, or files outside the Nix-managed configuration.
- Project-local dependency commands, such as `bun install` inside `scripts/bun/`, may update a project's dependencies and lockfiles.
- T3 Code, Claude Code, Codex and pstack update themselves. Nix only installs them the first time, in `home/linux/programs/t3code.nix`, `home/shared/programs/agent-clis.nix` and `system/agents.nix`. Do not package them in Nix or pin their versions.

## Agent configuration

- Claude Code and Codex share one global instruction file: `dotfiles/agents/AGENTS.md`. Its `## pstack model configuration` section is the pstack model sheet for both harnesses and for the Codex Cloud bootstrap.
- Put Claude-only rules in `dotfiles/claude/CLAUDE.md`, below its imports.
- Put Codex-only rules in a `developer_instructions` key on the Codex config in `system/agents.nix`. Codex has no include syntax, and its `AGENTS.override.md` replaces the shared file instead of adding to it.
- Refer to pstack skills by name in the shared file instead of importing or inlining them, so both harnesses read the version they have installed.
- Edit model rows in the repo. Do not run `/setup-pstack`: it overwrites the sheet, which links to the shared file.
- A skill is a folder with a `SKILL.md` in `dotfiles/agents/skills`. Codex sees a new skill at once. Claude Code sees it after the next `task rebuild`, which adds its link.

## Verification

- Agents may stage newly added, imported Nix files when flake evaluation requires it; do not stage unrelated changes.

## Rebuild permissions

- After `task check` passes, run `task rebuild` on nixbook from the checkout that holds the change. Do not ask Michael first.
- An agent on nixbook has no terminal for the sudo prompt:
  1. Call T3 Code's `request_secret` with `delivery: "file"`.
  2. Run `SUDO_PASSWORD_FILE=<file> task rebuild`.
  3. Delete the file.
- If `task rebuild` needs a terminal, such as on the Mac, ask Michael to run it.
