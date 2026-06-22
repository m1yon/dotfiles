# macOS Nix-Darwin Support Implementation Plan

## Goal

Add first-class macOS support to this Nix/Home Manager dotfiles repo while preserving Linux support. The end state should allow a fresh Apple Silicon MacBook to be bootstrapped from this repo using `nix-darwin`, Home Manager, and `nix-homebrew`.

## Settled Design

- Full macOS system support through `darwinConfigurations.macbook`.
- Linux host renamed from `nixos` to `nixbook`.
- Reusable Linux OS modules remain under `nixos/`.
- Host entrypoints live under `hosts/`.
- Shared Home Manager config has no OS conditionals.
- OS-specific Home Manager config lives in `home/linux` and `home/darwin`.
- Homebrew is fallback-only for packages missing or problematic in nixpkgs.
- Homebrew itself is managed by `nix-homebrew`.
- Native Apple Silicon Homebrew only; no Rosetta Homebrew initially.
- Homebrew cleanup is strict: `homebrew.onActivation.cleanup = "zap"`.
- macOS system defaults are small and safe.
- Touch ID sudo is enabled.
- Existing `rebuild`, `rebuild-home`, and `setup` tasks become platform-aware.

## Target Layout

```text
hosts/
  nixbook/
    default.nix
    hardware-configuration.nix
  macbook/
    default.nix

nixos/
  configuration.nix
  boot.nix
  networking.nix
  desktop.nix
  ...

darwin/
  configuration.nix
  homebrew.nix
  system.nix
  nix.nix

home/
  users/
    michael.nix
  shared/
    default.nix
    packages.nix
    env.nix
    shell.nix
    scripts/
      default.nix
      scripts-bash.nix
      scripts-bun.nix
    programs/
      default.nix
      atuin.nix
      git.nix
      neovim.nix
      ...
  linux/
    default.nix
    hyprland.nix
    shell.nix
    packages.nix
    programs/
      default.nix
      browsers.nix
      waybar.nix
      ...
    services/
      default.nix
      cloudflared.nix
      onedrive.nix
      ...
  darwin/
    default.nix
    packages.nix
    shell.nix
```

Move the existing Home Manager modules into the profile that owns them instead of keeping top-level `home/programs`, `home/services`, and `home/scripts` trees. Shared modules should live under `home/shared`, Linux-only modules under `home/linux`, and macOS-only modules under `home/darwin`. Imports should be local within each profile, for example `home/shared/default.nix` imports `./programs`, not `../programs/*`.

## Phase 1: Flake Inputs

Add these inputs:

```nix
nix-darwin = {
  url = "github:nix-darwin/nix-darwin/nix-darwin-25.11";
  inputs.nixpkgs.follows = "nixpkgs";
};

nix-homebrew.url = "github:zhaofengli/nix-homebrew";

homebrew-core = {
  url = "github:homebrew/homebrew-core";
  flake = false;
};

homebrew-cask = {
  url = "github:homebrew/homebrew-cask";
  flake = false;
};
```

Keep the existing stable `nixpkgs` and Home Manager pairing for the first pass. If Darwin evaluation exposes branch issues, introduce a separate Darwin nixpkgs input later.

## Phase 2: Flake Host Table

Replace the current single hardcoded host values with a small host table:

```nix
hosts = {
  nixbook = {
    system = "x86_64-linux";
    username = "michael";
    homeDirectory = "/home/michael";
    nixConfigDir = "/home/michael/GitHub/dotfiles";
  };

  macbook = {
    system = "aarch64-darwin";
    username = "michael";
    homeDirectory = "/Users/michael";
    nixConfigDir = "/Users/michael/GitHub/dotfiles";
  };
};
```

Refactor the unstable overlay to be system-aware:

```nix
unstableOverlay = final: prev:
let
  unstablePkgs = import inputs.nixpkgs-unstable {
    system = prev.stdenv.hostPlatform.system;
    config.allowUnfree = true;
  };
in {
  yazi = unstablePkgs.yazi;
  jetbrains = prev.jetbrains // {
    datagrip = unstablePkgs.jetbrains.datagrip;
  };
};
```

Add helpers:

```nix
mkPkgs = host: import nixpkgs {
  inherit (host) system;
  config.allowUnfree = true;
  overlays = [ unstableOverlay ];
};

mkSpecialArgs = hostName: host: {
  inherit inputs;
  username = host.username;
  hostname = hostName;
  homeDirectory = host.homeDirectory;
  nixConfigDir = host.nixConfigDir;
};
```

## Phase 3: Flake Outputs

Replace the old outputs with:

```nix
nixosConfigurations.nixbook = nixpkgs.lib.nixosSystem {
  system = hosts.nixbook.system;
  specialArgs = mkSpecialArgs "nixbook" hosts.nixbook;
  modules = [
    { nixpkgs.overlays = [ unstableOverlay ]; }
    ./hosts/nixbook
  ];
};
```

Add Darwin:

```nix
darwinConfigurations.macbook = inputs.nix-darwin.lib.darwinSystem {
  system = hosts.macbook.system;
  specialArgs = mkSpecialArgs "macbook" hosts.macbook;
  modules = [
    { nixpkgs.overlays = [ unstableOverlay ]; }
    ./hosts/macbook
  ];
};
```

Add host-qualified standalone Home Manager outputs:

```nix
homeConfigurations."michael@nixbook" = home-manager.lib.homeManagerConfiguration {
  pkgs = mkPkgs hosts.nixbook;
  extraSpecialArgs = mkSpecialArgs "nixbook" hosts.nixbook;
  modules = [
    inputs.sops-nix.homeManagerModules.sops
    inputs.stylix.homeModules.stylix
    ./home/users/michael.nix
    ./home/linux
  ];
};

homeConfigurations."michael@macbook" = home-manager.lib.homeManagerConfiguration {
  pkgs = mkPkgs hosts.macbook;
  extraSpecialArgs = mkSpecialArgs "macbook" hosts.macbook;
  modules = [
    inputs.sops-nix.homeManagerModules.sops
    inputs.stylix.homeModules.stylix
    ./home/users/michael.nix
    ./home/darwin
  ];
};
```

Remove or stop exposing the old `homeConfigurations.michael`.

## Phase 4: Host Entrypoints

Create `hosts/nixbook/default.nix`:

```nix
{
  imports = [
    ./hardware-configuration.nix
    ../../nixos/configuration.nix
  ];
}
```

Move `nixos/hardware-configuration.nix` to:

```text
hosts/nixbook/hardware-configuration.nix
```

Create `hosts/macbook/default.nix`:

```nix
{
  imports = [
    ../../darwin/configuration.nix
  ];
}
```

## Phase 5: NixOS Module Cleanup

Remove the hardware import from `nixos/configuration.nix`.

Current:

```nix
imports = [
  ./hardware-configuration.nix
  ./boot.nix
  ...
];
```

Target:

```nix
imports = [
  ./boot.nix
  ./networking.nix
  ...
];
```

Keep `nixos/networking.nix` using `hostname`, so the actual system hostname becomes `nixbook`.

## Phase 6: Darwin System Modules

Create `darwin/configuration.nix`:

```nix
{
  imports = [
    ./nix.nix
    ./system.nix
    ./homebrew.nix
  ];
}
```

Create `darwin/nix.nix`:

```nix
{ pkgs, ... }:

{
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  nixpkgs.config.allowUnfree = true;
}
```

Create `darwin/system.nix`:

```nix
{ pkgs, username, homeDirectory, ... }:

{
  system.primaryUser = username;
  system.stateVersion = 6;

  users.users.${username} = {
    name = username;
    home = homeDirectory;
    shell = pkgs.zsh;
  };

  programs.zsh.enable = true;
  security.pam.services.sudo_local.touchIdAuth = true;

  system.defaults = {
    dock = {
      autohide = true;
      show-recents = false;
    };

    finder = {
      AppleShowAllExtensions = true;
      FXPreferredViewStyle = "clmv";
    };

    NSGlobalDomain = {
      AppleShowAllExtensions = true;
      NSDocumentSaveNewDocumentsToCloud = false;
    };
  };
}
```

Create `darwin/homebrew.nix`:

```nix
{ config, inputs, username, ... }:

{
  imports = [
    inputs.nix-homebrew.darwinModules.nix-homebrew
  ];

  nix-homebrew = {
    enable = true;
    user = username;
    mutableTaps = false;
    taps = {
      "homebrew/homebrew-core" = inputs.homebrew-core;
      "homebrew/homebrew-cask" = inputs.homebrew-cask;
    };
  };

  homebrew = {
    enable = true;
    taps = builtins.attrNames config.nix-homebrew.taps;

    onActivation = {
      autoUpdate = false;
      upgrade = false;
      cleanup = "zap";
    };

    brews = [ ];
    casks = [ ];
    masApps = { };
  };
}
```

## Phase 7: Embedded Home Manager

Add Home Manager integration to both host systems.

For NixOS, keep the existing pattern but move it into the NixOS host path:

```nix
home-manager.nixosModules.home-manager
{
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.${username}.imports = [
    ../../home/users/michael.nix
    ../../home/linux
  ];
  home-manager.extraSpecialArgs = mkSpecialArgs "nixbook" hosts.nixbook;
  home-manager.sharedModules = [
    inputs.sops-nix.homeManagerModules.sops
    inputs.stylix.homeModules.stylix
  ];
}
```

For Darwin:

```nix
inputs.home-manager.darwinModules.home-manager
{
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.${username}.imports = [
    ../../home/users/michael.nix
    ../../home/darwin
  ];
  home-manager.extraSpecialArgs = mkSpecialArgs "macbook" hosts.macbook;
  home-manager.sharedModules = [
    inputs.sops-nix.homeManagerModules.sops
    inputs.stylix.homeModules.stylix
  ];
}
```

Because `mkSpecialArgs` is defined in `flake.nix`, this may be easier to inline in the flake modules rather than bury inside `hosts/*/default.nix`.

## Phase 8: Home Manager Split

Create `home/users/michael.nix`:

```nix
{ username, ... }:

{
  imports = [
    ../shared
  ];

  home.username = username;
  home.stateVersion = "25.11";
}
```

Create `home/shared/default.nix`:

```nix
{
  imports = [
    ./env.nix
    ./packages.nix
    ./programs
    ./scripts
    ./shell.nix
  ];
}
```

Move portable program modules from `home/programs` into `home/shared/programs` and create `home/shared/programs/default.nix`:

```nix
{
  imports = [
    ./atuin.nix
    ./awscli.nix
    ./btm.nix
    ./bun.nix
    ./claude-code.nix
    ./claude-devtools.nix
    ./coderabbit.nix
    ./difftastic.nix
    ./direnv.nix
    ./eza.nix
    ./fzf.nix
    ./git.nix
    ./gpg.nix
    ./go-task.nix
    ./lazycommit.nix
    ./lazygit.nix
    ./neovim.nix
    ./nixfmt.nix
    ./opencode.nix
    ./sftp.nix
    ./sops.nix
    ./ssh.nix
    ./starship.nix
    ./t3code.nix
    ./tealdeer.nix
    ./yazi.nix
    ./zoxide.nix
  ];
}
```

Move `home/scripts` to `home/shared/scripts`.

Create `home/shared/packages.nix` with the portable base packages from current `home/home.nix`:

```nix
{ pkgs, ... }:

{
  home.packages = [
    pkgs.bat
    pkgs.coreutils
    pkgs.dnsutils
    pkgs.fd
    pkgs.file
    pkgs.gnumake
    pkgs.just
    pkgs.lsof
    pkgs.openssl
    pkgs.pkg-config
    pkgs.ripgrep
    pkgs.sqlite
    pkgs.tree
    pkgs.uv
    pkgs.wget
    pkgs.yq-go
    pkgs.zip
  ];

  home.sessionPath = [
    "$HOME/.local/bin"
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    MANPAGER = "nvim +Man!";
    AWS_SDK_LOAD_CONFIG = 1;
  };
}
```

Create `home/shared/env.nix` for shared environment variables that use host metadata:

```nix
{ nixConfigDir, ... }:

{
  home.sessionVariables.NIX_CONFIG_DIR = nixConfigDir;
}
```

## Phase 9: Linux Home Profile

Create `home/linux/default.nix`:

```nix
{
  imports = [
    ./hyprland.nix
    ./packages.nix
    ./programs
    ./services
    ./shell.nix
  ];
}
```

Create `home/linux/packages.nix`:

```nix
{ homeDirectory, ... }:

{
  home.homeDirectory = homeDirectory;

  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };
}
```

Move Linux-only program modules from `home/programs` into `home/linux/programs` and create `home/linux/programs/default.nix`:

```nix
{
  imports = [
    ./browsers.nix
    ./datagrip.nix
    ./discord.nix
    ./docker.nix
    ./ghostty.nix
    ./gtk.nix
    ./hidpi.nix
    ./linear.nix
    ./localsend.nix
    ./ntfy.nix
    ./obsidian.nix
    ./onlyoffice.nix
    ./playerctl.nix
    ./screenshot.nix
    ./slack.nix
    ./spotify.nix
    ./stylix.nix
    ./todoist.nix
    ./vibetyper.nix
    ./vicinae.nix
    ./waybar.nix
    ./webapps.nix
  ];
}
```

Move Linux-only service modules from `home/services` into `home/linux/services` and create `home/linux/services/default.nix`:

```nix
{
  imports = [
    ./cloudflared.nix
    ./hyprpaper.nix
    ./mako.nix
    ./onedrive.nix
    ./opencode-web.nix
  ];
}
```

Move the Hyprland and pointer cursor config out of `home/home.nix` into `home/linux/hyprland.nix`.

Create `home/linux/shell.nix` for Linux-only shell aliases:

```nix
{
  programs.zsh.shellAliases.open = "setsid xdg-open";
}
```

## Phase 10: Darwin Home Profile

Create `home/darwin/default.nix`:

```nix
{
  imports = [
    ./packages.nix
    ./shell.nix
  ];
}
```

Create `home/darwin/packages.nix`:

```nix
{ pkgs, homeDirectory, ... }:

{
  home.homeDirectory = homeDirectory;

  home.packages = [
    pkgs.google-chrome
    pkgs.ghostty
    pkgs.obsidian
    pkgs.slack
    pkgs.spotify
  ];
}
```

This package list must be adjusted during evaluation. If a nixpkgs package does not exist or is broken on `aarch64-darwin`, remove it from `home/darwin/packages.nix` and add its cask name to `darwin/homebrew.nix`.

Create `home/darwin/shell.nix`:

```nix
{
  programs.zsh.shellAliases = {
    open = "open";
  };
}
```

Move the portable parts of the existing `home/programs/zsh.nix` into `home/shared/shell.nix`, including the `y()` helper and shared aliases like `src`. Keep OS-specific `open` aliases in `home/linux/shell.nix` and `home/darwin/shell.nix`.

## Phase 11: Retire Old Home Entrypoint

Stop using `home/home.nix` as the main entrypoint.

Either delete it later or leave it temporarily unused. For the first pass, leave it unused to reduce risk. Once `nix flake check` passes for both hosts, remove or simplify it.

Remove these old aggregate modules once the files have moved:

```text
home/programs/default.nix
home/services/default.nix
home/scripts/default.nix
```

Also remove the old top-level `home/programs`, `home/services`, and `home/scripts` directories after their files have been moved into `home/shared`, `home/linux`, or `home/darwin`.

## Phase 12: Taskfile Updates

Update `rebuild` to detect OS:

```yaml
rebuild:
  desc: Rebuild system configuration and switch
  cmds:
    - |
      case "$(uname -s)" in
        Darwin)
          sudo darwin-rebuild switch --flake {{.FLAKE_DIR}}#macbook
          ;;
        Linux)
          nixos-rebuild switch --flake {{.FLAKE_DIR}}#nixbook --sudo
          restart-app vicinae server
          ;;
        *)
          echo "Unsupported OS: $(uname -s)" >&2
          exit 1
          ;;
      esac
```

Update `rebuild-home`:

```yaml
rebuild-home:
  desc: Rebuild Home Manager configuration independently
  cmds:
    - |
      case "$(uname -s)" in
        Darwin)
          nix run home-manager -- switch --flake {{.FLAKE_DIR}}#michael@macbook
          ;;
        Linux)
          nix run home-manager -- switch --flake {{.FLAKE_DIR}}#michael@nixbook
          restart-app vicinae server
          ;;
        *)
          echo "Unsupported OS: $(uname -s)" >&2
          exit 1
          ;;
      esac
```

Update `setup`:

```yaml
setup:
  desc: Run setup tasks for a fresh machine
  cmds:
    - task: sops-age-key
    - |
      case "$(uname -s)" in
        Darwin)
          ;;
        Linux)
          task onedrive-reauth -- personal
          task onedrive-reauth -- carecoordinators
          ;;
        *)
          echo "Unsupported OS: $(uname -s)" >&2
          exit 1
          ;;
      esac
```

Consider making `onedrive-*` tasks Linux-only or documenting they are Linux-only.

## Phase 13: Validation

Run formatting:

```sh
task format
```

Run Linux eval/build checks:

```sh
nix flake check
nix build .#nixosConfigurations.nixbook.config.system.build.toplevel
nix build .#homeConfigurations."michael@nixbook".activationPackage
```

Run Darwin evaluation from Linux if possible:

```sh
nix eval .#darwinConfigurations.macbook.config.system.build.toplevel.drvPath
nix eval .#homeConfigurations."michael@macbook".activationPackage.drvPath
```

Do not expect a full Darwin build from Linux to work reliably unless remote builders or cross support are configured. Evaluation is still useful.

On the Mac, run:

```sh
sudo nix run nix-darwin/nix-darwin-25.11#darwin-rebuild -- switch --flake .#macbook
```

After nix-darwin is installed:

```sh
task rebuild
```

## Expected Breakages To Fix

- Some current Home Manager modules may reference Linux-only packages or options and need to move from shared to Linux.
- `programs.ghostty` settings like `gtk-single-instance` may not apply cleanly on Darwin.
- `gpg-agent` Home Manager service may behave differently on macOS.
- `llm-agents`, `t3code-nix`, or wrapper-module packages may not expose `aarch64-darwin` outputs.
- `pkgs.google-chrome`, `pkgs.slack`, `pkgs.spotify`, or `pkgs.obsidian` may be missing or broken on Darwin and should move to Homebrew casks.
- Strict Homebrew `zap` can remove any existing unlisted Homebrew apps on an already-used Mac.

## Fresh Mac Bootstrap

Expected flow on a fresh Mac:

```sh
xcode-select --install
```

Install Nix with the preferred installer.

Clone repo:

```sh
mkdir -p ~/GitHub
git clone <repo-url> ~/GitHub/dotfiles
cd ~/GitHub/dotfiles
```

First activation:

```sh
sudo nix run nix-darwin/nix-darwin-25.11#darwin-rebuild -- switch --flake .#macbook
```

After that:

```sh
task rebuild
```

## Execution Order

1. Add flake inputs and refactor host table.
2. Add `hosts/nixbook` and move hardware config.
3. Add `darwin/` modules.
4. Move Home Manager modules into `home/users`, `home/shared`, `home/linux`, and `home/darwin`.
5. Wire NixOS and Darwin embedded Home Manager.
6. Add host-qualified standalone Home Manager outputs.
7. Update `Taskfile.yml`.
8. Format.
9. Evaluate Linux.
10. Evaluate Darwin.
11. Fix module/package portability issues.
12. Test on the Mac.
