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

  ccstatusline = pkgs.stdenv.mkDerivation rec {
    pname = "ccstatusline";
    version = "2.2.8";
    src = pkgs.fetchurl {
      url = "https://registry.npmjs.org/ccstatusline/-/ccstatusline-${version}.tgz";
      hash = "sha256-4+fZ8yDlKwi+mJIMHEkPgyt8vA0kN3FcaEmUbXU7ctw=";
    };
    nativeBuildInputs = [ pkgs.makeWrapper ];
    dontConfigure = true;
    dontBuild = true;
    installPhase = ''
      runHook preInstall
      mkdir -p $out/lib/ccstatusline $out/bin
      cp dist/ccstatusline.js $out/lib/ccstatusline/
      makeWrapper ${pkgs.nodejs}/bin/node $out/bin/ccstatusline \
        --add-flags $out/lib/ccstatusline/ccstatusline.js
      runHook postInstall
    '';
  };
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
    env.CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "";
    env.DISABLE_TELEMETRY = "";
    extraPackages = (with pkgs; [
      typescript-language-server
      gopls
      nodejs
    ]) ++ [ ccstatusline ];
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
          args = [
            "-y"
            "@xeroapi/xero-mcp-server@latest"
          ];
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
    ".claude/rules".source = outOfStore "${dotfiles}/claude/rules";
    ".claude/statusline-command.sh".source = outOfStore "${dotfiles}/claude/statusline-command.sh";
    ".claude/statusline-wrapper.sh".source = outOfStore "${dotfiles}/claude/statusline-wrapper.sh";
    ".claude/claude-notifications-go/config.json".source =
      outOfStore "${dotfiles}/claude/claude-notifications-go/config.json";
    ".config/ccstatusline/settings.json".source = outOfStore "${dotfiles}/ccstatusline/settings.json";
  };
}
