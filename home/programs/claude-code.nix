{
  config,
  lib,
  pkgs,
  inputs,
  nixConfigDir,
  ...
}:

let
  dotfiles = "${nixConfigDir}/dotfiles";
  outOfStore = config.lib.file.mkOutOfStoreSymlink;

  mattpocock-skills = lib.pipe (builtins.readDir inputs.mattpocock-skills) [
    (lib.filterAttrs (_: type: type == "directory"))
    (lib.mapAttrs' (name: _:
      lib.nameValuePair ".claude/skills/${name}" {
        source = "${inputs.mattpocock-skills}/${name}";
      }
    ))
  ];
in
{
  imports = [
    inputs.nix-wrapper-modules.homeModules.claude-code
  ];

  wrappers.claude-code = {
    enable = true;
    package = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.claude-code;
    addFlag = [ "--dangerously-skip-permissions" ];
    env._ZO_DOCTOR = "0";
    extraPackages = with pkgs; [
      typescript-language-server
      gopls
    ];
  };

  home.file = {
    ".claude/CLAUDE.md".source = outOfStore "${dotfiles}/claude/CLAUDE.md";
    ".claude/settings.json".source = outOfStore "${dotfiles}/claude/settings.json";
    ".claude/skills/resolve-pr-feedback".source = "${dotfiles}/claude/skills/resolve-pr-feedback";
    ".claude/claude-notifications-go/config.json".source = outOfStore "${dotfiles}/claude/claude-notifications-go/config.json";
  } // mattpocock-skills;
}
