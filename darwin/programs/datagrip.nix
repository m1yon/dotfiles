{
  nixConfigDir,
  username,
  ...
}:

let
  dotfiles = "${nixConfigDir}/dotfiles";
in
{
  homebrew.casks = [ "datagrip" ];

  home-manager.users.${username} =
    { config, ... }:
    {
      home.file.".ideavimrc".source =
        config.lib.file.mkOutOfStoreSymlink "${dotfiles}/datagrip/.ideavimrc";
    };
}
