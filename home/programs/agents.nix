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
    ".agents/skills".source = outOfStore "${dotfiles}/agents/skills";
    ".agents/.skill-lock.json".source = outOfStore "${dotfiles}/agents/.skill-lock.json";
    ".claude/skills".source = outOfStore "${dotfiles}/agents/skills";
  };
}
