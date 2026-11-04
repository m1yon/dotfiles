{ pkgs, ... }:

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

  services.displayManager.gdm = {
    enable = true;
    # Nobody sits at the login screen of a closed-lid server, so it must not suspend.
    autoSuspend = false;
  };
  services.desktopManager.gnome.enable = true;

  # The Nix config owns these settings, and both would prompt on first login.
  services.gnome.gnome-initial-setup.enable = false;
  environment.gnome.excludePackages = [ pkgs.gnome-tour ];

  environment.sessionVariables.TERMINAL = "ghostty";

  environment.systemPackages = with pkgs; [
    git
    psmisc
    jq
    unzip
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];
}
