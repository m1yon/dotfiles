{
  lib,
  pkgs,
  ...
}:

let
  # Both harnesses follow upstream through their own updaters. Claude leaves
  # auto-update off for third-party marketplaces unless it's set here.
  pstackUrl = "https://github.com/michael-denyer/pstack-claude.git";

  claudeManagedSettings = (pkgs.formats.json { }).generate "claude-managed-settings.json" (
    {
      extraKnownMarketplaces.pstack-claude = {
        source = {
          source = "git";
          url = pstackUrl;
        };
        autoUpdate = true;
      };
      enabledPlugins."pstack@pstack-claude" = true;
    }
    // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
      permissions.defaultMode = "bypassPermissions";
      env = {
        _ZO_DOCTOR = "0";
        GH_PROMPT_DISABLED = "true";
        GH_PAGER = "less";
      };
    }
  );

  codexSystemConfig = (pkgs.formats.toml { }).generate "codex-config.toml" {
    features.hooks = true;
    marketplaces.pstack-claude = {
      source_type = "git";
      source = pstackUrl;
    };
    plugins."pstack@pstack-claude".enabled = true;
  };

  claudeManagedDir = "/Library/Application Support/ClaudeCode/managed-settings.d";
in
{
  # The apps keep rewriting ~/.claude/settings.json and ~/.codex/config.toml, so
  # the repo's declarations live in the system layers each harness also reads.
  environment.etc = {
    "codex/config.toml".source = codexSystemConfig;
    "claude-code/managed-settings.d/dotfiles.json" = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      source = claudeManagedSettings;
    };
  };

  system.activationScripts = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    postActivation.text = lib.mkAfter ''
      echo "installing Claude Code managed settings..." >&2
      install -d -m 0755 ${lib.escapeShellArg claudeManagedDir}
      install -m 0644 ${claudeManagedSettings} ${lib.escapeShellArg "${claudeManagedDir}/dotfiles.json"}
    '';
  };
}
