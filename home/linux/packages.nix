{ homeDirectory, pkgs, ... }:

{
  home.homeDirectory = homeDirectory;

  home.packages = [ pkgs.wl-clipboard ];

  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };
}
