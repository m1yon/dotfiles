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
  programs.neovim = {
    enable = true;
  };
  home.file = {
    ".config/nvim/".source = outOfStore "${dotfiles}/nvim";
  };
}
