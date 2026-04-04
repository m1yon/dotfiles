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
      nodejs
    ];
  };

  sops.secrets = {
    xero_client_id.sopsFile = ../../secrets/xero.yaml;
    xero_client_secret.sopsFile = ../../secrets/xero.yaml;
  };

  sops.templates."mcp.json" = {
    path = "${config.home.homeDirectory}/.mcp.json";
    content = builtins.toJSON {
      mcpServers = {
        mercury = {
          type = "http";
          url = "https://mcp.mercury.com/mcp";
        };
        xero = {
          command = "npx";
          args = [ "-y" "@xeroapi/xero-mcp-server@latest" ];
          env = {
            XERO_CLIENT_ID = config.sops.placeholder.xero_client_id;
            XERO_CLIENT_SECRET = config.sops.placeholder.xero_client_secret;
          };
        };
      };
    };
  };

  home.file = {
    ".claude/CLAUDE.md".source = outOfStore "${dotfiles}/claude/CLAUDE.md";
    ".claude/settings.json".source = outOfStore "${dotfiles}/claude/settings.json";
    ".claude/skills".source = outOfStore "${dotfiles}/claude/skills";
    ".claude/claude-notifications-go/config.json".source =
      outOfStore "${dotfiles}/claude/claude-notifications-go/config.json";
  };
}
