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

  # voice-mode pulls in simpleaudio/pyaudio which build C extensions against
  # ALSA/portaudio at install time. NixOS doesn't expose system headers via
  # /usr/include, so we have to inject a working build environment for uv.
  voicemodeBuildInputs = with pkgs; [
    alsa-lib
    portaudio
  ];
  voicemode = pkgs.writeShellScriptBin "voicemode" ''
    export PATH=${
      pkgs.lib.makeBinPath [
        pkgs.uv
        pkgs.stdenv.cc
        pkgs.pkg-config
      ]
    }''${PATH:+:$PATH}
    export PKG_CONFIG_PATH=${
      pkgs.lib.makeSearchPath "lib/pkgconfig" (map (p: p.dev or p) voicemodeBuildInputs)
    }''${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}
    export CPATH=${
      pkgs.lib.makeSearchPath "include" (map (p: p.dev or p) voicemodeBuildInputs)
    }''${CPATH:+:$CPATH}
    export LIBRARY_PATH=${
      pkgs.lib.makeLibraryPath voicemodeBuildInputs
    }''${LIBRARY_PATH:+:$LIBRARY_PATH}
    export LD_LIBRARY_PATH=${
      pkgs.lib.makeLibraryPath voicemodeBuildInputs
    }''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
    exec uvx --from voice-mode voicemode "$@"
  '';
in
{
  imports = [
    inputs.nix-wrapper-modules.homeModules.claude-code
  ];

  wrappers.claude-code = {
    enable = true;
    package = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.claude-code;
    addFlag = [
      "--dangerously-skip-permissions"
    ];
    env._ZO_DOCTOR = "0";
    env.CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "";
    env.DISABLE_TELEMETRY = "";
    env.GH_PROMPT_DISABLED = "true";
    env.GH_PAGER = "less";
    extraPackages =
      (with pkgs; [
        typescript-language-server
        gopls
        nodejs
        uv
        ffmpeg
      ])
      ++ [
        ccstatusline
        voicemode
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
          args = [
            "-y"
            "@xeroapi/xero-mcp-server@latest"
          ];
          env = {
            XERO_CLIENT_ID = config.sops.placeholder.xero_client_id;
            XERO_CLIENT_SECRET = config.sops.placeholder.xero_client_secret;
          };
        };
        voicemode = {
          command = "${voicemode}/bin/voicemode";
          args = [ ];
        };
      };
    };
  };

  home.file = {
    ".claude/CLAUDE.md".source = outOfStore "${dotfiles}/claude/CLAUDE.md";
    ".claude/settings.json".source = outOfStore "${dotfiles}/claude/settings.json";
    ".claude/rules".source = outOfStore "${dotfiles}/claude/rules";
    ".claude/statusline-command.sh".source = outOfStore "${dotfiles}/claude/statusline-command.sh";
    ".claude/statusline-wrapper.sh".source = outOfStore "${dotfiles}/claude/statusline-wrapper.sh";
    ".claude/claude-notifications-go/config.json".source =
      outOfStore "${dotfiles}/claude/claude-notifications-go/config.json";
    ".config/ccstatusline/settings.json".source = outOfStore "${dotfiles}/ccstatusline/settings.json";
  };
}
