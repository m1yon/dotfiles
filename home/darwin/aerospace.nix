{ config, nixConfigDir, pkgs, ... }:

let
  dotfiles = "${nixConfigDir}/dotfiles";
  outOfStore = config.lib.file.mkOutOfStoreSymlink;
in
{
  home.packages = [
    pkgs.aerospace
  ];

  home.file.".aerospace.toml" = {
    source = outOfStore "${dotfiles}/aerospace/aerospace.toml";
    force = true;
  };
}
