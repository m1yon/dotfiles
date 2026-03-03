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
  home.file = {
    ".config/hypr/hyprland.conf".source = outOfStore "${dotfiles}/hyprland/hyprland.conf";
  };
}
