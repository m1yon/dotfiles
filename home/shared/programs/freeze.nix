{
  config,
  lib,
  pkgs,
  nixConfigDir,
  ...
}:

let
  # Freeze's adrg/xdg library uses Application Support on macOS unless XDG is set.
  configHome =
    config.home.sessionVariables.XDG_CONFIG_HOME or (
      if pkgs.stdenv.hostPlatform.isDarwin then
        "${config.home.homeDirectory}/Library/Application Support"
      else
        config.xdg.configHome
    );
in
{
  # macOS already installs Freeze through the declarative Homebrew tap.
  home.packages = lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.charm-freeze ];

  home.file."${configHome}/freeze/user.json" = {
    source = config.lib.file.mkOutOfStoreSymlink "${nixConfigDir}/dotfiles/freeze/user.json";
    # Replace the previously saved user config when adopting the managed file.
    force = true;
  };
}
