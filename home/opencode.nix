
{ config, pkgs, inputs, ... }:

let
  dotfiles = "/home/michael/GitHub/dotfiles/dotfiles";
  outOfStore = config.lib.file.mkOutOfStoreSymlink;
in
{
  home.file = {
    ".config/opencode/".source = outOfStore "${dotfiles}/opencode";
  };
}
