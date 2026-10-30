{
  config,
  nixConfigDir,
  ...
}:

let
  dotfiles = "${nixConfigDir}/dotfiles";
  outOfStore = config.lib.file.mkOutOfStoreSymlink;
in
{
  home.file = {
    ".codex/AGENTS.md" = {
      source = outOfStore "${dotfiles}/agents/AGENTS.md";
      force = true;
    };
  };
}
