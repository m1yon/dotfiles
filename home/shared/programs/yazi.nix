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
    shellWrapperName = "yy";
  };
  home.file = {
    ".config/yazi/".source = outOfStore "${dotfiles}/yazi";
  };
}
