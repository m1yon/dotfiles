{ config, pkgs, dotfilesPath, ... }:

let
  dotfiles = "${dotfilesPath}/dotfiles";
  outOfStore = config.lib.file.mkOutOfStoreSymlink;
in
{
  home.file = {
    ".config/hypr/".source = outOfStore "${dotfiles}/hyprland";
  };
}
