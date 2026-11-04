{ ... }:

{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  nix.settings = {
    auto-optimise-store = true;
    trusted-users = [
      "root"
      "@wheel"
    ];
    substituters = [
      "https://cache.numtide.com"
    ];
    trusted-substituters = [
      "https://cache.numtide.com"
    ];
    trusted-public-keys = [
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    download-buffer-size = 268435456;
  };

  nixpkgs.config.allowUnfree = true;

  system.stateVersion = "25.11";
}
