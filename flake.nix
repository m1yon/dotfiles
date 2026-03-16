{
  description = "A simple NixOS flake";

  nixConfig = {
    extra-substituters = [ "https://cache.numtide.com" ];
    extra-trusted-public-keys = [ "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g=" ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
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
    stylix = {
      url = "github:danth/stylix/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    tt-schemes = {
      url = "github:tinted-theming/schemes";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      llm-agents,
      sops-nix,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      username = "michael";
      hostname = "nixos";
      nixConfigDir = "/home/${username}/GitHub/dotfiles";
      unstablePkgs = import inputs.nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };
      unstableOverlay = final: prev: {
        yazi = unstablePkgs.yazi;
      };
    in
    {
      nixosConfigurations.${hostname} = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs username nixConfigDir hostname; };
        modules = [
          { nixpkgs.overlays = [ unstableOverlay ]; }
          ./nixos/configuration.nix

          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;

            home-manager.users.${username} = import ./home/home.nix;

            home-manager.extraSpecialArgs = { inherit inputs username nixConfigDir hostname; };
            home-manager.sharedModules = [
              inputs.sops-nix.homeManagerModules.sops
              inputs.stylix.homeModules.stylix
            ];
          }
        ];
      };

      # Standalone Home Manager configuration
      # Use with: home-manager switch --flake .
      # Works on non-NixOS systems (plain Linux, WSL, etc.)
      homeConfigurations.${username} = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = [ unstableOverlay ];
        };
        extraSpecialArgs = { inherit inputs username nixConfigDir; };
        modules = [
          inputs.sops-nix.homeManagerModules.sops
          inputs.stylix.homeModules.stylix
          ./home/home.nix
        ];
      };
    };
}
