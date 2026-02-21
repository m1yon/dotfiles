{ config, pkgs, ... }:

let
  dotfiles = "/home/michael/GitHub/dotfiles/dotfiles";
  outOfStore = config.lib.file.mkOutOfStoreSymlink;
in
{
  programs.neovim = {
    enable = true;
  };
  home.file = {
    ".config/nvim/".source = outOfStore "${dotfiles}/nvim";
  };
}
