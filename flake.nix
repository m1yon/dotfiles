{
  description = "A simple NixOS flake";

  nixConfig = {
    extra-substituters = [ "https://cache.numtide.com" ];
    extra-trusted-public-keys = [ "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g=" ];
  };

  inputs = {
    # NixOS official package source, using the nixos-25.11 branch here
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    # home-manager, used for managing user configuration
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      # The `follows` keyword in inputs is used for inheritance.
      # Here, `inputs.nixpkgs` of home-manager is kept consistent with
      # the `inputs.nixpkgs` of the current flake,
      # to avoid problems caused by different versions of nixpkgs.
      inputs.nixpkgs.follows = "nixpkgs";
    };
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
    };
    hyprland = {
      url = "github:hyprwm/Hyprland";
    };
  };

  outputs = { self, nixpkgs, home-manager, llm-agents, ... }@inputs:
    let
      username = "michael";
      dotfilesPath = "/home/${username}/GitHub/dotfiles";
    in
    {
    # Please replace my-nixos with your hostname
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs username dotfilesPath; };
      modules = [
        ./nixos/configuration.nix

	  # make home-manager as a module of nixos
          # so that home-manager configuration will be deployed automatically when executing `nixos-rebuild switch`
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;

            home-manager.users.${username} = import ./home/home.nix;

            home-manager.extraSpecialArgs = { inherit inputs username dotfilesPath; };
          }
      ];
    };

    # Standalone Home Manager configuration
    # Use with: home-manager switch --flake .
    # Works on non-NixOS systems (plain Linux, WSL, etc.)
    homeConfigurations.${username} = home-manager.lib.homeManagerConfiguration {
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        config.allowUnfree = true;
      };
      extraSpecialArgs = { inherit inputs username dotfilesPath; };
      modules = [
        ./home/home.nix
      ];
    };
  };
}
