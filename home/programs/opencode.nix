{
  config,
  pkgs,
  inputs,
  nixConfigDir,
  ...
}:

let
  dotfiles = "${nixConfigDir}/dotfiles";
  outOfStore = config.lib.file.mkOutOfStoreSymlink;
in
{
  home.packages = [
    inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.opencode
  ];

  home.sessionVariables = {
    OPENCODE_ENABLE_EXA = "true";
    OPENCODE_EXPERIMENTAL_WORKSPACES = "true";
  };

  home.file = {
    ".config/opencode/".source = outOfStore "${dotfiles}/opencode";
  };
}
