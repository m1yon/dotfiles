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
  programs.lazygit = {
    enable = true;
  };
  home.file = {
    ".config/lazygit/".source = outOfStore "${dotfiles}/lazygit";
  };
}
