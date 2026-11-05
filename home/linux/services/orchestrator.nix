{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.orchestrator;

  # The code is one detached worktree of the private repo per commit, under
  # releases/. orchestrator-deploy builds a release completely, then repoints
  # the current symlink at it. A private flake input would break evaluation for
  # any machine without GitHub credentials.
  repo = "${config.home.homeDirectory}/GitHub/orchestrator";
  base = "${config.xdg.dataHome}/orchestrator";
  releases = "${base}/releases";
  checkout = "${base}/current";
  stateDir = "${config.xdg.stateHome}/orchestrator";

  dryRun = cfg.mode == "dry-run";
  tokenFromGh = cfg.githubToken == "gh";

  startLimitBurst = 15;

  serve = pkgs.writeShellApplication {
    name = "orchestrator-serve";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.git
    ]
    ++ lib.optional tokenFromGh config.programs.gh.package;
    text = ''
      mkdir -p "$(dirname "$ORCH_STATE")"
      if [ ! -x ${checkout}/node_modules/.bin/bun ]; then
        echo "orchestrator-serve: no deployed release at ${checkout}. Run orchestrator-deploy." >&2
        exit 1
      fi
      # -P pins one release even if a deploy repoints current while this starts.
      cd -P ${checkout}
      bun=./node_modules/.bin/bun
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
      pkgs.coreutils
      pkgs.findutils
      pkgs.git
      pkgs.util-linux
    ];
    text = ''
      ctl="${config.systemd.user.systemctlPath} --user"
      building=""

      fail() {
        echo "orchestrator-deploy: $*" >&2
        exit 1
      }

      drop_release() {
        git -C ${repo} worktree remove --force "$1" 2>/dev/null || rm -rf "$1"
        git -C ${repo} worktree prune
      }

      # rename(2) swaps the symlink in one step.
      point_current() {
        ln -sfn "$1" ${base}/current.new
        mv -T ${base}/current.new ${checkout}
      }

      trap '[ -z "$building" ] || drop_release "$building"' EXIT

      mkdir -p ${releases}
      exec 9>${base}/deploy.lock
      flock -n 9 || fail "another deploy is running."

      git -C ${repo} fetch --quiet origin main || fail "git fetch failed. current is unchanged."
      sha=$(git -C ${repo} rev-parse --verify "origin/main^{commit}")
      short=$(git -C ${repo} rev-parse --short "$sha")
      release=${releases}/$sha

      # Only .deployed marks a release as complete. Anything else under this
      # name is left over from a build that was killed, so build it again.
      if [ ! -e "$release/.deployed" ]; then
        drop_release "$release"
        building=$release
        git -C ${repo} worktree add --quiet --detach "$release" "$sha" ||
          fail "could not check out $short. current is unchanged."
        (cd "$release" && bun install --frozen-lockfile) ||
          fail "bun install failed for $short. current is unchanged."
        "$release/node_modules/.bin/bun" --version ||
          fail "the pinned Bun in $short does not run. current is unchanged."
        touch "$release/.deployed"
        building=""
      fi

      previous=$(readlink ${checkout} || true)
      point_current "releases/$sha"
      if ! { $ctl reset-failed orchestrator.service && $ctl restart orchestrator.service; }; then
        if [ -n "$previous" ]; then point_current "$previous"; else rm -f ${checkout}; fi
        fail "could not restart orchestrator.service. current is as it was before this deploy."
      fi

      # The two newest releases stay, so a bad deploy can go back by hand.
      find ${releases} -mindepth 2 -maxdepth 2 -name .deployed -printf '%T@ %h\n' |
        sort -rn | tail -n +3 | cut -d' ' -f2- |
        while read -r old; do
          [ "$old" = "$release" ] || drop_release "$old"
        done

      echo "orchestrator-deploy: now on $short"
    '';
  };

  # The service's own ntfy alert cannot fire when the process never starts.
  notifyFailure = pkgs.writeShellApplication {
    name = "orchestrator-notify-failure";
    runtimeInputs = [ pkgs.curl ];
    text = ''
      # systemd runs OnFailure= after every failed exit, even when a retry
      # follows. Only the last failure has this result.
      [ "''${MONITOR_SERVICE_RESULT:-}" = start-limit-hit ] || exit 0
      # The header comes in on stdin so the token never shows in argv.
      if printf 'header = "Authorization: %s"\n' "$ORCH_NTFY_TOKEN" |
        curl --silent --show-error --fail --max-time 20 --config - \
          -H "Title: Orchestrator gave up starting" \
          -H "Priority: 5" \
          -H "Tags: warning,skull" \
          -H "Markdown: yes" \
          -d "The orchestrator service failed to start ${toString startLimitBurst} times and systemd stopped retrying. Run \`journalctl --user -u orchestrator\`." \
          "$ORCH_NTFY_URL"; then
        echo "orchestrator-notify-failure: sent the notice to ntfy"
      else
        echo "orchestrator-notify-failure: could not send the notice to ntfy" >&2
      fi
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

    # Only orchestrator-env reads this. The value includes the "Bearer " prefix,
    # so it goes into the Authorization header as it is.
    sops.secrets.ntfy_auth_token.sopsFile = ../../../secrets/ntfy.yaml;

    sops.secrets.orchestrator_github_token = lib.mkIf (!tokenFromGh) {
      sopsFile = ../../../secrets/github.yaml;
    };

    # The topic is the one the removed OpenCode ntfy-notify.sh published to.
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
        StartLimitIntervalSec = 900;
        StartLimitBurst = startLimitBurst;
        OnFailure = [ "orchestrator-notify-failure.service" ];
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

    systemd.user.services.orchestrator-notify-failure = {
      Unit.Description = "Tell Michael the orchestrator gave up starting";
      Service = {
        Type = "oneshot";
        EnvironmentFile = config.sops.templates."orchestrator-env".path;
        ExecStart = lib.getExe notifyFailure;
        UMask = "0077";
        NoNewPrivileges = true;
      };
    };
  };
}
