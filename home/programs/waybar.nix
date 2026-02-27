{ config, pkgs, dotfilesPath, ... }:

let
  dotfiles = "${dotfilesPath}/dotfiles";
  outOfStore = config.lib.file.mkOutOfStoreSymlink;
in
{
  programs.waybar = {
    enable = true;
  };
  home.file = {
    ".config/waybar/".source = outOfStore "${dotfiles}/waybar";
  };
}
