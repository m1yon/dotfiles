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
    inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.opencode
    pkgs.nodejs
  ];

  home.sessionVariables = {
    OPENCODE_ENABLE_EXA = "true";
    OPENCODE_EXPERIMENTAL_WORKSPACES = "true";
  };

  sops.secrets = {
    ynab_api_token.sopsFile = ../../../secrets/ynab.yaml;
    ynab_budget_id.sopsFile = ../../../secrets/ynab.yaml;
  };

  sops.templates."opencode-mcp-env" = {
    content = ''
      export YNAB_API_TOKEN="${config.sops.placeholder.ynab_api_token}"
      export YNAB_BUDGET_ID="${config.sops.placeholder.ynab_budget_id}"
    '';
  };

  programs.zsh.initContent = ''
    [ -f "${config.sops.templates."opencode-mcp-env".path}" ] && source "${
      config.sops.templates."opencode-mcp-env".path
    }"
  '';

  home.file = {
    ".config/opencode/AGENTS.md".source = outOfStore "${dotfiles}/agents/AGENTS.md";
    ".config/opencode/dcp.jsonc".source = outOfStore "${dotfiles}/opencode/dcp.jsonc";
    ".config/opencode/ntfy-notify.sh".source = outOfStore "${dotfiles}/opencode/ntfy-notify.sh";
    ".config/opencode/opencode-notifier.json".source =
      outOfStore "${dotfiles}/opencode/opencode-notifier.json";
    ".config/opencode/opencode.json".source = outOfStore "${dotfiles}/opencode/opencode.json";
  };
}
