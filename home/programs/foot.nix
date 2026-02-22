{ config, pkgs, ... }:

let
  dotfiles = "/home/michael/GitHub/dotfiles/dotfiles";
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
