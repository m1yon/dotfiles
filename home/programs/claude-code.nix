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
    inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.claude-code
  ];

  home.file = {
    ".claude/settings.json".source = outOfStore "${dotfiles}/claude/settings.json";
    ".claude/skills".source = outOfStore "${dotfiles}/claude/skills";
  };
}
