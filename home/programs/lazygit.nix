{ config, pkgs, ... }:

let
  dotfiles = "/home/michael/GitHub/dotfiles/dotfiles";
  outOfStore = config.lib.file.mkOutOfStoreSymlink;
in
{
  programs.lazygit = {
    enable = true;
  };
  home.file = {
    ".config/lazygit/".source = outOfStore "${dotfiles}/lazygit";
  };
}
