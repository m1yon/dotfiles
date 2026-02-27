{ config, pkgs, dotfilesPath, ... }:

let
  dotfiles = "${dotfilesPath}/dotfiles";
  outOfStore = config.lib.file.mkOutOfStoreSymlink;
in
{
  programs.yazi = {
    enable = true;
  };
  home.file = {
    ".config/yazi/".source = outOfStore "${dotfiles}/yazi";
  };
}
