{
  config,
  pkgs,
  dotfilesPath,
  ...
}:

let
  dotfiles = "${dotfilesPath}/dotfiles";
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
