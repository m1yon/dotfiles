{ nixConfigDir, ... }:

{
  home.sessionVariables.NIX_CONFIG_DIR = nixConfigDir;
}
