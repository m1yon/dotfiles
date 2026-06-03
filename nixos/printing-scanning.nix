{
  pkgs,
  username,
  ...
}:

{
  services.printing = {
    enable = true;
    webInterface = true;
    browsed.enable = true;
    drivers = with pkgs; [
      brlaser
      epson-escpr
      gutenprint
      hplip
      splix
    ];
  };

  hardware.sane = {
    enable = true;
    extraBackends = with pkgs; [
      epsonscan2
      sane-airscan
    ];
  };

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  users.users.${username}.extraGroups = [
    "scanner"
    "lp"
  ];

  environment.systemPackages = with pkgs; [
    cups
    simple-scan
    system-config-printer
  ];
}
