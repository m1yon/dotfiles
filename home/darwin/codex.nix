{ config, nixConfigDir, ... }:

let
  dotfiles = "${nixConfigDir}/dotfiles";
  outOfStore = config.lib.file.mkOutOfStoreSymlink;
in
{
  home.file = {
    ".codex/AGENTS.md" = {
      source = outOfStore "${dotfiles}/codex/AGENTS.md";
      force = true;
    };
  };
}
