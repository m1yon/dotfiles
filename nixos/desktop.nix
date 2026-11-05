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
    autoSuspend = false;
  };
  services.desktopManager.gnome.enable = true;

  # The Nix config owns these settings, and both would prompt on first login.
  services.gnome.gnome-initial-setup.enable = false;
  environment.gnome.excludePackages = [ pkgs.gnome-tour ];

  # This machine is a remote worker, so it skips the screen reader, speech, and file indexing that GNOME enables by default.
  services.orca.enable = false;
  services.speechd.enable = false;
  services.gnome.localsearch.enable = false;

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
