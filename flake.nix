{
  description = "A simple NixOS flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
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
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
    };
    nix-wrapper-modules = {
      url = "github:BirdeeHub/nix-wrapper-modules";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      ...
    }@inputs:
    let
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

      unstableOverlay =
        final: prev:
        let
          unstablePkgs = import inputs.nixpkgs-unstable {
            system = prev.stdenv.hostPlatform.system;
            config.allowUnfree = true;
          };
        in
        {
          gh = unstablePkgs.gh;
          yazi = unstablePkgs.yazi;
        };

      # T3 Code runs inside appimage-run's bubblewrap sandbox, whose /etc links only a
      # fixed list of host entries. Add the directories system/agents.nix fills, or
      # harnesses started by T3 miss their system config. T3's updater relaunches
      # through binfmt, so the launcher and programs.appimage need the same package.
      appimageRunOverlay = final: prev: {
        appimage-run = prev.appimage-run.override {
          buildFHSEnv =
            args:
            final.buildFHSEnv (
              args
              // {
                extraBwrapArgs = (args.extraBwrapArgs or [ ]) ++ [
                  "--symlink /.host-etc/codex /etc/codex"
                  "--symlink /.host-etc/claude-code /etc/claude-code"
                ];
              }
            );
        };
      };

      mkPkgs =
        host:
        import nixpkgs {
          inherit (host) system;
          config.allowUnfree = true;
          overlays = [
            unstableOverlay
            appimageRunOverlay
          ];
        };

      mkSpecialArgs = hostName: host: {
        inherit inputs;
        username = host.username;
        hostname = hostName;
        homeDirectory = host.homeDirectory;
        nixConfigDir = host.nixConfigDir;
      };
    in
    {
      nixosConfigurations.nixbook = nixpkgs.lib.nixosSystem {
        system = hosts.nixbook.system;
        specialArgs = mkSpecialArgs "nixbook" hosts.nixbook;
        modules = [
          {
            nixpkgs.overlays = [
              unstableOverlay
              appimageRunOverlay
            ];
          }
          ./hosts/nixbook

          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.${hosts.nixbook.username}.imports = [
              ./home/users/michael.nix
              ./home/linux
            ];
            home-manager.extraSpecialArgs = mkSpecialArgs "nixbook" hosts.nixbook;
            home-manager.sharedModules = [
              inputs.sops-nix.homeManagerModules.sops
            ];
          }
        ];
      };

      darwinConfigurations.macbook = inputs.nix-darwin.lib.darwinSystem {
        system = hosts.macbook.system;
        specialArgs = mkSpecialArgs "macbook" hosts.macbook;
        modules = [
          { nixpkgs.overlays = [ unstableOverlay ]; }
          ./hosts/macbook

          inputs.home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.${hosts.macbook.username}.imports = [
              ./home/users/michael.nix
              ./home/darwin
            ];
            home-manager.extraSpecialArgs = mkSpecialArgs "macbook" hosts.macbook;
            home-manager.sharedModules = [
              inputs.sops-nix.homeManagerModules.sops
            ];
          }
        ];
      };

      homeConfigurations."michael@nixbook" = home-manager.lib.homeManagerConfiguration {
        pkgs = mkPkgs hosts.nixbook;
        extraSpecialArgs = mkSpecialArgs "nixbook" hosts.nixbook;
        modules = [
          inputs.sops-nix.homeManagerModules.sops
          ./home/users/michael.nix
          ./home/linux
        ];
      };

      homeConfigurations."michael@macbook" = home-manager.lib.homeManagerConfiguration {
        pkgs = mkPkgs hosts.macbook;
        extraSpecialArgs = mkSpecialArgs "macbook" hosts.macbook;
        modules = [
          inputs.sops-nix.homeManagerModules.sops
          ./home/users/michael.nix
          ./home/darwin
        ];
      };

      checks = nixpkgs.lib.genAttrs [ hosts.nixbook.system hosts.macbook.system ] (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          outputs = {
            nixbook = inputs.self.nixosConfigurations.nixbook.config.system.build.toplevel;
            macbook = inputs.self.darwinConfigurations.macbook.system;
            home-nixbook = inputs.self.homeConfigurations."michael@nixbook".activationPackage;
            home-macbook = inputs.self.homeConfigurations."michael@macbook".activationPackage;
          };
          tests = {
            # Writing each output's derivation path evaluates it without building it.
            evaluate = pkgs.writeText "evaluated-outputs" (
              nixpkgs.lib.concatLines (
                nixpkgs.lib.mapAttrsToList (
                  name: drv: "${name} ${builtins.unsafeDiscardStringContext drv.drvPath}"
                ) outputs
              )
            );
            agent-guard = pkgs.runCommand "agent-guard-test" { nativeBuildInputs = [ pkgs.jq ]; } ''
              ${pkgs.bash}/bin/bash ${./system/agent-guard-test.sh} \
                ${pkgs.callPackage ./system/agent-guard.nix { }}/bin/agent-guard
              touch $out
            '';
          };
        in
        tests // { all = pkgs.linkFarmFromDrvs "all-checks" (builtins.attrValues tests); }
      );
    };
}
