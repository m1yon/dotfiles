{
  pkgs,
  inputs,
  osConfig ? null,
  ...
}:

let
  hyprlandPackages = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system};
  useSystemHyprland = osConfig != null && (osConfig.programs.hyprland.enable or false);
in
{
  home.pointerCursor = {
    name = "rose-pine-hyprcursor";
    package = inputs.rose-pine-hyprcursor.packages.${pkgs.stdenv.hostPlatform.system}.default;
    size = 24;
    gtk.enable = true;
    hyprcursor.enable = true;
  };

  wayland.windowManager.hyprland.enable = true;
  wayland.windowManager.hyprland.systemd.enable = false;
  wayland.windowManager.hyprland.package =
    if useSystemHyprland then null else hyprlandPackages.hyprland;
  wayland.windowManager.hyprland.portalPackage =
    if useSystemHyprland then null else hyprlandPackages.xdg-desktop-portal-hyprland;
}
