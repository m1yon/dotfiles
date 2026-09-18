---
name: fleet
description: Work with Michael's computer fleet. Use when a task involves the MacBook, nixbook Linux laptop, connecting between them, choosing where to run commands, or managing their shared Nix configuration.
---

# Fleet

## Computers

| Computer | Platform | User and home | Dotfiles checkout | System flake output |
| --- | --- | --- | --- | --- |
| MacBook, `macbook` | Apple Silicon macOS, `aarch64-darwin`, nix-darwin | `michael`, `/Users/michael` | `/Users/michael/GitHub/dotfiles` | `darwinConfigurations.macbook` |
| nixbook, Linux laptop | NixOS, `x86_64-linux` | `michael`, `/home/michael` | `/home/michael/GitHub/dotfiles` | `nixosConfigurations.nixbook` |

The inventory comes from `flake.nix` in the dotfiles checkout. Recheck it when changing hosts or paths. `macbook` is the flake identifier; it does not establish a reachable DNS name or SSH alias.

## Choose the execution host

Check `uname -s`, `hostname`, and `pwd` before host-specific work. A task viewed in the Mac's Codex app can execute entirely on nixbook. Its shell commands and filesystem tools act on the task's host.

Use local tools when already on the target computer. Otherwise use a verified SSH connection. Keep macOS commands and `/Users/michael` paths on the MacBook, and Linux commands and `/home/michael` paths on nixbook. Treat the two Git checkouts as independent; check the branch and worktree before editing or transferring changes.

## MacBook

Use a task running locally on the MacBook for macOS work. The dotfiles repo does not currently establish an SSH server or a verified connection from nixbook to the MacBook. If remote Mac access is needed, confirm the endpoint and access method with Michael before relying on it.

For configuration changes, start with `hosts/macbook/default.nix`, `darwin/`, and `home/darwin/` in its dotfiles checkout. Use `launchctl` for service inspection when relevant.

## nixbook

From the MacBook, use `ssh nixbook-tailnet` as `michael` for access through Tailscale. `darwin/programs/tailscale.nix` declares the Mac app and a system SSH alias targeting the MagicDNS name `nixbook`. `nixos/networking.nix` enables the Linux daemon. Both hosts need a rebuild and enrollment in the same tailnet before this connection works; configuration alone does not establish connectivity. Read "Remote access with Tailscale" in `README.md` for enrollment and verification.

The existing SOPS-managed `ssh nixbook` alias is the LAN connection. Linux OpenSSH accepts keys, disables root and password login, and authorizes the Mac's key. Tailscale supplies network connectivity; its separate SSH authentication feature is disabled.

Inspect connection settings with `ssh -G nixbook-tailnet`. Successful configuration expansion alone does not prove connectivity. A bounded, read-only check is:

```sh
ssh -o BatchMode=yes -o ConnectTimeout=10 nixbook-tailnet 'uname -s; hostname; id -un'
```

Use a login shell when remote commands need the Nix/Home Manager environment:

```sh
ssh nixbook-tailnet 'zsh -lc "cd /home/michael/GitHub/dotfiles && git status --short"'
```

For configuration changes, start with `hosts/nixbook/default.nix`, `nixos/`, and `home/linux/`. Inspect user services with `systemctl --user`; inspect system services with `systemctl`.

The Mac's Codex app can connect over SSH to nixbook's `codex-app-server` user service. For connection troubleshooting, read the "Codex on nixbook from the Mac app" section of `README.md` and `home/linux/services/codex.nix`. Useful checks on nixbook are:

```sh
systemctl --user is-active codex-app-server
journalctl --user -u codex-app-server -n 50 --no-pager
```

The configured lid behavior keeps nixbook awake when plugged in or docked. Closing the lid on battery otherwise suspends it. Remote work needs power and connectivity.

## Shared configuration and skills

Read the dotfiles checkout's `AGENTS.md` before making changes. Manage packages, services, and settings through its Nix modules. Shared Home Manager configuration lives in `home/shared/`; host-specific configuration belongs in the platform directories above.

Verify Nix changes with the relevant eval or check and resolve warnings. Leave rebuilds and switches to Michael, including `task rebuild`, `task rebuild-home`, and update tasks that invoke a rebuild. After verification, ask him to run `task rebuild` from the target computer's dotfiles checkout.

SSH configuration is SOPS-managed through `home/shared/programs/ssh.nix`. Use the `sops` skill when changing the encrypted source; keep decrypted configuration and private keys out of this skill and Git.

Global skills live in `dotfiles/agents/skills/` within each checkout. `home/shared/programs/agents.nix` links that directory to `~/.agents/skills` and `~/.claude/skills`. Edit the shared source. An existing link exposes new skill files without a rebuild; the other computer needs the corresponding checkout changes too.
