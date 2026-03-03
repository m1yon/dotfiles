{
  config,
  pkgs,
  nixConfigDir,
  ...
}:

let
  dotfiles = "${nixConfigDir}/dotfiles";
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
