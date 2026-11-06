{
  config,
  lib,
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

  # Claude Code writes its own folders, such as synced/ and .trash/, into
  # ~/.claude/skills. Linking each skill keeps that directory in $HOME, so those
  # writes stay out of the repo.
  skillsDir = ../../../dotfiles/agents/skills;
  skillNames = lib.attrNames (
    lib.filterAttrs (
      name: type: type == "directory" && builtins.pathExists (skillsDir + "/${name}/SKILL.md")
    ) (builtins.readDir skillsDir)
  );
  claudeSkills = lib.listToAttrs (
    map (
      name:
      lib.nameValuePair ".claude/skills/${name}" {
        source = outOfStore "${dotfiles}/agents/skills/${name}";
        force = true;
      }
    ) skillNames
  );
in
{
  home.file = {
    ".agents/AGENTS.md" = sharedInstructions;
    ".agents/skills".source = outOfStore "${dotfiles}/agents/skills";
    ".claude/agents".source = outOfStore "${dotfiles}/claude/agents";
    ".claude/CLAUDE.md" = {
      source = outOfStore "${dotfiles}/claude/CLAUDE.md";
      force = true;
    };
    ".claude/pstack-models.md" = sharedInstructions;
    ".codex/AGENTS.md" = sharedInstructions;
    ".codex/pstack-models.md" = sharedInstructions;
    ".local/state/skills/.skill-lock.json".source = outOfStore "${dotfiles}/agents/.skill-lock.json";
  }
  // claudeSkills;

  # Older generations linked ~/.claude/skills itself into the repo. Home Manager
  # links each skill through that parent link, onto the skill's repo folder, and
  # activation fails. Remove the old link before the link check.
  home.activation.unlinkClaudeSkillsDir = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    if [ -L "$HOME/.claude/skills" ]; then
      run rm "$HOME/.claude/skills"
    fi
  '';
}
