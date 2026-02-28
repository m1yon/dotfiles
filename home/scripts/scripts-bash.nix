{
  config,
  dotfilesPath,
  ...
}:

let
  outOfStore = config.lib.file.mkOutOfStoreSymlink;
in
{
  home.file.".local/bin" = {
    source = outOfStore "${dotfilesPath}/scripts-bash";
    recursive = true;
  };
}
