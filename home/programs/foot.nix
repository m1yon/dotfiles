{ config, pkgs, dotfilesPath, ... }:

let
  dotfiles = "${dotfilesPath}/dotfiles";
  outOfStore = config.lib.file.mkOutOfStoreSymlink;
in
{
  programs.foot = {
    enable = true;
  };
  home.file = {
    ".config/foot/".source = outOfStore "${dotfiles}/foot";
  };
}
