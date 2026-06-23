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

    ".codex/config.toml" = {
      source = outOfStore "${dotfiles}/codex/config.toml";
      force = true;
    };
  };
}
