{ pkgs, ... }:

{
  home.packages = with pkgs; [
    onlyoffice-desktopeditors
  ];

  xdg.configFile."onlyoffice/DesktopEditors.conf".text = ''
    [General]
    UITheme = "theme-contrast-dark"
    titlebar = "custom"
  '';
}
