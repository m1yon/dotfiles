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
    ".claude/skills".source = outOfStore "${dotfiles}/agents/skills";
    ".claude/agents".source = outOfStore "${dotfiles}/claude/agents";
    ".claude/CLAUDE.md" = {
      source = outOfStore "${dotfiles}/claude/CLAUDE.md";
      force = true;
    };
    ".claude/pstack-models.md" = {
      source = outOfStore "${dotfiles}/claude/pstack-models.md";
      force = true;
    };
    ".local/state/skills/.skill-lock.json".source = outOfStore "${dotfiles}/agents/.skill-lock.json";
  };
}
