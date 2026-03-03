{
  lib,
  pkgs,
  inputs,
  ...
}:

{
  time.timeZone = "America/Denver";

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    portalPackage =
      inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
  };

  programs.uwsm.waylandCompositors.hyprland.binPath =
    lib.mkForce "/run/current-system/sw/bin/start-hyprland";

  programs.uwsm.enable = true;

  programs.zsh.loginShellInit = lib.mkAfter ''
    if uwsm check may-start; then
      exec uwsm start hyprland-uwsm.desktop
    fi
  '';

  programs.thunar.enable = true;
  programs.xfconf.enable = true;
  programs.dconf.enable = true;
  services.gvfs.enable = true;
  services.tumbler.enable = true;

  services.printing.enable = true;

  environment.systemPackages = with pkgs; [
    git
    psmisc
    jq
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];
}
