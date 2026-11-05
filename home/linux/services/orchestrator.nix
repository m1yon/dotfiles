{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.orchestrator;

  # The code is a detached worktree of the private repo, moved by
  # orchestrator-deploy. A private flake input would break evaluation for any
  # machine without GitHub credentials.
  repo = "${config.home.homeDirectory}/GitHub/orchestrator";
  checkout = "${config.xdg.dataHome}/orchestrator/current";
  stateDir = "${config.xdg.stateHome}/orchestrator";

  dryRun = cfg.mode == "dry-run";
  tokenFromGh = cfg.githubToken == "gh";

  serve = pkgs.writeShellApplication {
    name = "orchestrator-serve";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.git
    ]
    ++ lib.optional tokenFromGh config.programs.gh.package;
    text = ''
      mkdir -p "$(dirname "$ORCH_STATE")"
      cd ${checkout}
      bun=${checkout}/node_modules/.bin/bun
      ${lib.optionalString tokenFromGh ''
        ORCH_GITHUB_TOKEN=$(timeout 30 gh auth token)
        export ORCH_GITHUB_TOKEN
      ''}
      ORCH_HEALTH_HOST=$(/run/current-system/sw/bin/tailscale ip -4 | head -n 1)
      export ORCH_HEALTH_HOST
      [ -e "$ORCH_STATE" ] || "$bun" src/main.ts baseline
      exec "$bun" src/main.ts serve${lib.optionalString dryRun " --dry-run"}
    '';
  };

  deploy = pkgs.writeShellApplication {
    name = "orchestrator-deploy";
    runtimeInputs = [
      pkgs.bun
      pkgs.git
    ];
    text = ''
      git -C ${repo} fetch --quiet origin main
      if [ -e ${checkout}/.git ]; then
        git -C ${checkout} checkout --quiet --force --detach origin/main
      else
        mkdir -p "$(dirname ${checkout})"
        git -C ${repo} worktree add --quiet --detach ${checkout} origin/main
      fi
      cd ${checkout}
      bun install --frozen-lockfile
      ${config.systemd.user.systemctlPath} --user reset-failed orchestrator.service
      ${config.systemd.user.systemctlPath} --user restart orchestrator.service
      git rev-parse --short HEAD
    '';
  };
in
{
  options.services.orchestrator = {
    mode = lib.mkOption {
      type = lib.types.enum [
        "dry-run"
        "live"
      ];
      default = "dry-run";
      description = "dry-run plans and logs without writing to Todoist. live applies the plan.";
    };

    githubToken = lib.mkOption {
      type = lib.types.enum [
        "gh"
        "sops"
      ];
      default = "gh";
      description = ''
        gh runs `gh auth token` when the unit starts. sops reads
        orchestrator_github_token from secrets/github.yaml, for a read-only token.
      '';
    };

    healthPort = lib.mkOption {
      type = lib.types.port;
      default = 18900;
      description = "TCP port of /health, bound to the Tailscale address.";
    };
  };

  config = {
    home.packages = [ deploy ];

    sops.secrets = lib.mkIf (!tokenFromGh) {
      orchestrator_github_token.sopsFile = ../../../secrets/github.yaml;
    };

    sops.templates."orchestrator-env".content = ''
      ORCH_TODOIST_TOKEN=${config.sops.placeholder.todoist_api_token}
      ORCH_NTFY_URL=https://ntfy.sh/opencode-michael-lyon
      ORCH_NTFY_TOKEN=${config.sops.placeholder.ntfy_auth_token}
    ''
    + lib.optionalString (!tokenFromGh) ''
      ORCH_GITHUB_TOKEN=${config.sops.placeholder.orchestrator_github_token}
    '';

    systemd.user.services.orchestrator = {
      Unit = {
        Description = "Orchestrator (${cfg.mode})";
        After = [ "sops-nix.service" ];
        Wants = [ "sops-nix.service" ];
        # Skips the start until orchestrator-deploy has made the checkout.
        ConditionPathExists = "${checkout}/node_modules/.bin/bun";
        StartLimitIntervalSec = 900;
        StartLimitBurst = 15;
      };
      Service = {
        EnvironmentFile = config.sops.templates."orchestrator-env".path;
        Environment = [
          "ORCH_GITHUB_URL=https://api.github.com/graphql"
          "ORCH_GITHUB_AUTHOR=m1yon"
          "ORCH_TODOIST_URL=https://api.todoist.com/api/v1/sync"
          "ORCH_STATE=${stateDir}/state.db"
          "ORCH_HEALTH_PORT=${toString cfg.healthPort}"
        ]
        ++ lib.optional dryRun "ORCH_PLAN_LOG=${stateDir}/plan.jsonl";
        ExecStart = lib.getExe serve;
        Restart = "on-failure";
        RestartSec = 30;
        # A stop lets the run in flight finish.
        TimeoutStopSec = 120;
        UMask = "0077";
        NoNewPrivileges = true;
      };
      Install.WantedBy = [ "default.target" ];
    };
  };
}
