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
  programs.yazi = {
    enable = true;
  };
  home.file = {
    ".config/yazi/".source = outOfStore "${dotfiles}/yazi";
  };
}
