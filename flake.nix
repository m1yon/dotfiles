{
  description = "A simple NixOS flake";

  nixConfig = {
    extra-substituters = [ "https://cache.numtide.com" ];
    extra-trusted-public-keys = [ "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g=" ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
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
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
    };
    hyprland = {
      url = "github:hyprwm/Hyprland";
    };
    nix-wrapper-modules = {
      url = "github:BirdeeHub/nix-wrapper-modules";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rose-pine-hyprcursor = {
      url = "github:ndom91/rose-pine-hyprcursor";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    t3code-nix = {
      url = "github:Sawrz/t3code-nix";
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
          yazi = unstablePkgs.yazi;
          jetbrains = prev.jetbrains // {
            datagrip = unstablePkgs.jetbrains.datagrip;
          };
        };

      mkPkgs =
        host:
        import nixpkgs {
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
    in
    {
      nixosConfigurations.nixbook = nixpkgs.lib.nixosSystem {
        system = hosts.nixbook.system;
        specialArgs = mkSpecialArgs "nixbook" hosts.nixbook;
        modules = [
          { nixpkgs.overlays = [ unstableOverlay ]; }
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
    };
}
