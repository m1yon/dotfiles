{
  config,
  nixConfigDir,
  ...
}:

let
  dotfiles = "${nixConfigDir}/dotfiles";
  outOfStore = config.lib.file.mkOutOfStoreSymlink;

  # One file holds the shared rules and the pstack model rows. Codex can't include
  # other files and pstack reads its sheet by path, so every harness path links here.
  sharedInstructions = {
    source = outOfStore "${dotfiles}/agents/AGENTS.md";
    force = true;
  };
in
{
  home.file = {
    ".agents/AGENTS.md" = sharedInstructions;
    ".agents/skills".source = outOfStore "${dotfiles}/agents/skills";
    ".claude/skills".source = outOfStore "${dotfiles}/agents/skills";
    ".claude/agents".source = outOfStore "${dotfiles}/claude/agents";
    ".claude/CLAUDE.md" = {
      source = outOfStore "${dotfiles}/claude/CLAUDE.md";
      force = true;
    };
    ".claude/pstack-models.md" = sharedInstructions;
    ".codex/AGENTS.md" = sharedInstructions;
    ".codex/pstack-models.md" = sharedInstructions;
    ".local/state/skills/.skill-lock.json".source = outOfStore "${dotfiles}/agents/.skill-lock.json";
  };
}
