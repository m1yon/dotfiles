# dotfiles

NixOS, nix-darwin, Home Manager, and app dotfiles for Michael's machines.

## Hosts

- `nixbook`: Linux/NixOS host, exposed as `nixosConfigurations.nixbook`.
- `macbook`: Apple Silicon macOS host, exposed as `darwinConfigurations.macbook`.
- `michael@nixbook`: standalone Linux Home Manager output.
- `michael@macbook`: standalone macOS Home Manager output.

## Directory Structure

```text
.
├── flake.nix                 # Flake inputs, host table, NixOS/Darwin/Home Manager outputs
├── flake.lock                # Locked input revisions for reproducible builds
├── setup.sh                  # Fresh-machine bootstrap without requiring task
├── Taskfile.yml              # Day-to-day rebuild, update, format, and maintenance commands
├── hosts/                    # Machine entrypoints that compose OS modules with host hardware
│   ├── nixbook/              # Linux/NixOS laptop host
│   │   ├── default.nix       # Imports nixbook hardware and reusable NixOS modules
│   │   └── hardware-configuration.nix # Generated hardware/filesystem config for nixbook
│   └── macbook/              # Apple Silicon macOS host
│       └── default.nix       # Imports reusable nix-darwin modules
├── nixos/                    # Reusable Linux system modules shared by NixOS hosts
│   ├── configuration.nix     # Aggregate import list for Linux system modules
│   ├── boot.nix              # Bootloader, kernel, and boot-time settings
│   ├── networking.nix        # Hostname, wireless, and network tooling
│   ├── desktop.nix           # Hyprland, portals, fonts, and desktop services
│   ├── users.nix             # Linux user account and shell setup
│   └── ...
├── darwin/                   # Reusable macOS system modules for nix-darwin hosts
│   ├── configuration.nix     # Aggregate import list for Darwin system modules
│   ├── nix.nix               # Nix daemon and nixpkgs settings
│   ├── system.nix            # macOS user, shell, Touch ID sudo, and defaults
│   └── homebrew.nix          # nix-homebrew taps, casks, and activation cleanup
├── home/                     # Home Manager profiles and user-level configuration
│   ├── users/                # User entrypoints that import shared Home Manager config
│   │   └── michael.nix       # Michael's common Home Manager identity and state version
│   ├── shared/               # Common Home Manager config reused by both profiles
│   │   ├── default.nix       # Aggregate import list for shared modules
│   │   ├── env.nix           # Shared environment derived from host metadata
│   │   ├── packages.nix      # Portable base CLI packages and session variables
│   │   ├── shell.nix         # Portable zsh config, aliases, and shell helpers
│   │   ├── programs/         # Portable Home Manager program modules
│   │   │   ├── default.nix   # Aggregate import list for shared programs
│   │   │   └── ...
│   │   └── scripts/          # User script wiring for repo-managed script directories
│   │       ├── default.nix   # Aggregate import list for script modules
│   │       └── ...
│   ├── linux/                # Linux-only Home Manager profile
│   │   ├── default.nix       # Aggregate import list for Linux user modules
│   │   ├── hyprland.nix      # Hyprland and pointer cursor Home Manager settings
│   │   ├── packages.nix      # Linux home directory and session variables
│   │   ├── shell.nix         # Linux-specific shell aliases
│   │   ├── programs/         # Linux-only app and desktop program modules
│   │   │   ├── default.nix   # Aggregate import list for Linux programs
│   │   │   └── ...
│   │   └── services/         # Linux systemd user services managed by Home Manager
│   │       ├── default.nix   # Aggregate import list for Linux services
│   │       └── ...
│   └── darwin/               # macOS-only Home Manager profile
│       ├── default.nix       # Aggregate import list for macOS user modules
│       ├── packages.nix      # macOS home directory and Darwin Home packages
│       └── shell.nix         # macOS-specific shell aliases
├── dotfiles/                 # Raw app config linked into $HOME by Home Manager
│   ├── claude/               # Claude Code config, statusline, and rules
│   ├── opencode/             # OpenCode config and integrations
│   ├── nvim/                 # Neovim configuration
│   ├── waybar/               # Waybar configuration for Linux desktop
│   ├── yazi/                 # Yazi file manager configuration
│   └── ...
├── scripts/                  # Repo-managed scripts exposed on the Home Manager PATH
│   ├── bash/                 # Shell scripts by platform
│   │   ├── shared/           # Cross-platform shell scripts
│   │   ├── darwin/           # macOS-only shell scripts
│   │   └── linux/            # Linux-only shell scripts
│   └── bun/                  # Bun scripts by platform
│       └── src/              # shared, darwin, and linux Bun script workspaces
├── secrets/                  # SOPS-encrypted secrets consumed by Nix and Home Manager
├── wallpapers/               # Wallpaper assets used by desktop modules
└── docs/                     # Plans, architecture notes, and agent-facing documentation
```

## Bootstrap

Run the setup script directly on new machines before `task` is available:

```sh
./setup.sh
```

Then rebuild the platform-specific system configuration:

```sh
task rebuild
```

## Remote access with Tailscale

NixOS runs `tailscaled` on nixbook. nix-darwin installs the standalone Tailscale
Mac app and adds the system SSH alias `nixbook-tailnet`. The alias resolves
`nixbook` through Tailscale's MagicDNS and uses the existing OpenSSH server and
SSH keys. The SOPS-managed `nixbook` LAN alias remains available.

After syncing these changes to both checkouts, run `task rebuild` in each
computer's dotfiles checkout. Complete enrollment once per computer:

1. On nixbook, run `sudo tailscale up` and open the login URL. Sign in to your
   personal Tailscale account. Check `tailscale status` and `tailscale ip -4`.
2. On the MacBook, open Tailscale from Applications, approve its macOS system
   extension/VPN prompts, and sign in to the same account. Leave it connected.
3. In the [Tailscale admin console](https://login.tailscale.com/admin/machines),
   confirm both devices are connected and the Linux device is named `nixbook`.
   In [DNS settings](https://login.tailscale.com/admin/dns), confirm MagicDNS is
   enabled. An existing custom access policy must allow the Mac to reach
   nixbook on TCP port 22.
4. From a Mac terminal, run:

   ```sh
   /Applications/Tailscale.app/Contents/MacOS/Tailscale ping nixbook
   ssh nixbook-tailnet 'hostname; uname -s'
   ```

   Expect `nixbook` and `Linux`. For a first-time SSH host-key prompt, compare
   the fingerprint with `ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub` on
   nixbook. Repeat the connection from a phone hotspot to verify access away
   from the home network.

`ssh -G nixbook-tailnet` should report `hostname nixbook` and `user michael`.
If MagicDNS does not resolve, use the `100.x.y.z` address from `tailscale ip -4`
on nixbook with `ssh -o HostName=100.x.y.z nixbook-tailnet` while diagnosing DNS.
Enrollment credentials stay on the devices, outside Git.

The Linux service starts at boot and retains its login across reboots. Keep
nixbook plugged in and online. Check its key-expiry date in the admin console
before travel; an expired device key requires reauthentication.

References: [macOS setup](https://tailscale.com/docs/install/mac),
[MagicDNS](https://tailscale.com/docs/features/magicdns), and
[OpenSSH over Tailscale](https://tailscale.com/docs/reference/ssh-over-tailscale).

## Codex on nixbook from the Mac app

Both hosts install Codex CLI from the pinned `llm-agents` input. On Linux,
Home Manager runs `codex-app-server.service` on Codex's default Unix socket.
NixOS enables user lingering so the service starts at boot and survives logout.
The Mac app connects through SSH; no app-server TCP port is exposed.

After applying the configuration with `task rebuild` on nixbook:

1. Authenticate on nixbook as Michael:

   ```sh
   codex login --device-auth
   codex login status
   systemctl --user status codex-app-server
   ```

   Complete the device-code login in your browser. Device-code authentication
   may need enabling in your ChatGPT account or workspace. Credentials and
   conversations stay in `/home/michael/.codex`; they are not managed by Git.

2. Complete the Tailscale setup above and verify `ssh nixbook-tailnet` from the
   Mac. The Linux SSH server already authorizes the Mac's key. For LAN-only
   access, the existing SOPS-managed `nixbook` alias can also be used.

3. From the Mac, verify the remote login environment:

   ```sh
   ssh nixbook-tailnet 'zsh -lc "command -v codex && printenv CODEX_SSH_SKIP_APP_SERVER_BOOT && codex login status && systemctl --user is-active codex-app-server"'
   ```

   Expect a Codex path, `true`, a successful login status, and `active`.

4. In the Mac app, open **Settings > Connections > SSH**, add or enable
   `nixbook-tailnet`, and select a repository directory on Linux. Start the task in
   that remote project. Its agent, tools, and saved conversation run on Linux.

Keep nixbook powered and online. Closing its lid while plugged in does not
suspend it; closing the lid on battery still does, unless docked. Explicit
sleep, shutdown, and loss of connectivity can interrupt work. Tools and
credentials needed by the task must be available on Linux. Requests for human
input can wait for reconnection; tools supplied by the Mac app may require it
to remain connected.

Before relying on unattended work, start a task that performs a short command,
waits, and then performs another tool call. Disconnect the Mac and reconnect
after the wait. Verify the later tool call ran while disconnected and that the
same conversation is available. Check the Linux log if needed:

```sh
journalctl --user -u codex-app-server -n 100 --no-pager
```

### Manual updates

When Codex tasks are idle, run `task update-llm-agents` from the dotfiles checkout
on nixbook. This updates the input and rebuilds the system; it also updates
other tools provided by that input. Applying a changed service can restart
Codex and interrupt active tasks. No automatic update timer is configured.

Use `systemctl --user restart codex-app-server` if an explicit restart is
needed after updating, then reconnect the Mac app. Do not run `codex update`
or `codex app-server daemon bootstrap` for this installation: Nix manages the
package, and systemd manages the server.

The service enables Code Mode and uses the desktop app's
`CODEX_SSH_SKIP_APP_SERVER_BOOT=true` integration to avoid a second server.
Recheck that integration after major app/CLI updates. Upstream setup details:
[Codex SSH connections](https://learn.chatgpt.com/docs/remote-connections#connect-to-an-ssh-host).
