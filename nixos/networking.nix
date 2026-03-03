{ pkgs, ... }:

{
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;
  networking.networkmanager.wifi.backend = "iwd";
  networking.wireless.iwd.enable = true;

  environment.systemPackages = with pkgs; [
    impala
  ];

  environment.shellAliases = {
    wifi = "impala";
  };
}
