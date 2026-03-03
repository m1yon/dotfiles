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
  home.packages = [
    pkgs.jetbrains.datagrip
  ];

  home.file = {
    ".ideavimrc".source = outOfStore "${dotfiles}/datagrip/.ideavimrc";
  };
}
