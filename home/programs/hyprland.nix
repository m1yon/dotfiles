{
  nixConfigDir,
  ...
}:

let
  dotfiles = "${nixConfigDir}/dotfiles";
in
{
  home.file = {
    ".config/hypr/hyprland.conf".source = "${dotfiles}/hyprland/hyprland.conf";
  };
}
