{ pkgs, hostname, ... }:

{
  networking.hostName = hostname;
  networking.networkmanager.enable = false;
  networking.wireless.iwd = {
    enable = true;
    settings = {
      General = {
        EnableNetworkConfiguration = true;
        AddressRandomization = "once";
      };
      Network = {
        EnableIPv6 = true;
        RoutePriorityOffset = 300;
        NameResolvingService = "systemd";
      };
      Settings = {
        AutoConnect = true;
      };
    };
  };

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
    };
  };

  environment.systemPackages = with pkgs; [
    impala
  ];

  environment.shellAliases = {
    wifi = "impala";
  };
}
