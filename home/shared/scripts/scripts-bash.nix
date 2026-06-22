{
  config,
  nixConfigDir,
  ...
}:

let
  outOfStore = config.lib.file.mkOutOfStoreSymlink;
in
{
  home.file.".local/bin" = {
    source = outOfStore "${nixConfigDir}/scripts-bash";
    recursive = true;
  };
}
