{ homeDirectory, ... }:

{
  home.homeDirectory = homeDirectory;

  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };
}
