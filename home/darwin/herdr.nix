{
  config,
  nixConfigDir,
  ...
}:

{
  home.file.".config/herdr/config.toml" = {
    source = config.lib.file.mkOutOfStoreSymlink "${nixConfigDir}/dotfiles/herdr/config.toml";
    force = true;
  };
}
