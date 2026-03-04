{ pkgs, ... }:

{
  networking.hostName = "nixos";
  networking.networkmanager.enable = false;
  networking.wireless.iwd = {
    enable = true;
    settings = {
      General = {
        EnableNetworkConfiguration = true;
      };
      Network = {
        NameResolvingService = "systemd";
      };
      Settings = {
        AutoConnect = true;
      };
    };
  };

  systemd.network.enable = true;
  networking.useNetworkd = true;

  environment.systemPackages = with pkgs; [
    impala
  ];

  environment.shellAliases = {
    wifi = "impala";
  };
}
