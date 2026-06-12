{
  config,
  pkgs,
  inputs,
  osConfig ? null,
  username,
  nixConfigDir,
  ...
}:

let
  hyprlandPackages = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system};
  useSystemHyprland = osConfig != null && (osConfig.programs.hyprland.enable or false);
in
{
  home.username = username;
  home.homeDirectory = "/home/${username}";

  home.pointerCursor = {
    name = "rose-pine-hyprcursor";
    package = inputs.rose-pine-hyprcursor.packages.${pkgs.stdenv.hostPlatform.system}.default;
    size = 24;
    gtk.enable = true;
    hyprcursor.enable = true;
  };

  home.packages = [
    pkgs.bat
    pkgs.coreutils
    pkgs.dnsutils
    pkgs.fd
    pkgs.file
    pkgs.gnumake
    pkgs.just
    pkgs.lsof
    pkgs.openssl
    pkgs.pkg-config
    pkgs.ripgrep
    pkgs.sqlite
    pkgs.tree
    pkgs.uv
    pkgs.wget
    pkgs.yq-go
    pkgs.zip
  ];

  imports = [
    ./programs
    ./services
    ./scripts
  ];

  home.sessionPath = [
    "$HOME/.local/bin"
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    MANPAGER = "nvim +Man!";
    AWS_SDK_LOAD_CONFIG = 1;
    NIX_CONFIG_DIR = nixConfigDir;
    NIXOS_OZONE_WL = "1";
  };

  # hyprland
  wayland.windowManager.hyprland.enable = true;
  wayland.windowManager.hyprland.systemd.enable = false;
  wayland.windowManager.hyprland.package =
    if useSystemHyprland then null else hyprlandPackages.hyprland;
  wayland.windowManager.hyprland.portalPackage =
    if useSystemHyprland then null else hyprlandPackages.xdg-desktop-portal-hyprland;

  home.stateVersion = "25.11";
}
