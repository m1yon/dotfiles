{
  config,
  inputs,
  nixConfigDir,
  pkgs,
  ...
}:

let
  dotfiles = "${nixConfigDir}/dotfiles";
  outOfStore = config.lib.file.mkOutOfStoreSymlink;
in
{
  home.packages = [
    inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.codex
  ];

  home.file = {
    ".codex/AGENTS.md" = {
      source = outOfStore "${dotfiles}/agents/AGENTS.md";
      force = true;
    };
  };
}
