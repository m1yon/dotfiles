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
