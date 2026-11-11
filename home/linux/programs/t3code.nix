{ lib, pkgs, ... }:

let
  # T3 keeps each version in $T3CODE_HOME/runtime/versions and the one its
  # launcher runs in runtime/service-state.json, which `t3 service install` would
  # write along with a unit of its own. T3 installs later versions itself, and the
  # launcher rolls back a new version that fails to start. Updates can prune old
  # versions, so when that file is missing or names a version that is gone, this
  # runs the newest installed one, and installs one only when none is left.
  t3code-server = pkgs.writeShellApplication {
    name = "t3code-server";
    runtimeInputs = with pkgs; [
      coreutils
      curl
      gnugrep
      gnused
      gnutar
      gzip
      jq
      psmisc
    ];
    text = ''
      export T3CODE_HOME="''${T3CODE_HOME:-$HOME/.t3}"
      versions="$T3CODE_HOME/runtime/versions"
      state="$T3CODE_HOME/runtime/service-state.json"

      installed() {
        [ -x "$versions/$1/t3" ] && [ -e "$versions/$1/.install-complete" ]
      }

      newest() {
        local version
        for version in "$versions"/*/; do
          version="$(basename "$version")"
          if installed "$version"; then
            echo "$version"
          fi
        done | sort -V | tail -n 1
      }

      active="$(jq -r '.activeVersion // empty' "$state" 2>/dev/null || true)"
      if [ -z "$active" ] || ! installed "$active"; then
        active="$(newest)"
        if [ -z "$active" ]; then
          curl -fsSL https://t3.codes/install.sh | sh
          active="$(newest)"
        fi
        if [ -z "$active" ]; then
          echo "T3's installer finished, but $versions holds no installed version." >&2
          exit 1
        fi
        jq -n --arg version "$active" '{ protocol: 3, activeVersion: $version }' >"$state.tmp"
        mv "$state.tmp" "$state"
      fi

      # When another server, such as the desktop app, owns this T3 home, the
      # launcher idles until something restarts it. Wait for that owner to exit.
      while fuser -s "$T3CODE_HOME/userdata/server-owner.sqlite"; do
        sleep 5
      done

      exec "$versions/$active/t3" __service-launcher
    '';
  };
in
{
  # T3's CLI treats a t3code.service with an Environment=T3CODE_HOME line as its
  # own install for that home, and `t3 update` rewrites it. Leaving the line out
  # keeps the unit Nix-owned, so the wrapper sets T3CODE_HOME instead.
  systemd.user.services.t3code = {
    Unit = {
      Description = "T3 Code server";
      # Agents run `task rebuild` from inside T3 Code, so a switch must not
      # restart it under them.
      X-SwitchMethod = "keep-old";
      StartLimitIntervalSec = 0;
    };
    Service = {
      ExecStart = lib.getExe t3code-server;
      WorkingDirectory = "%h";
      Environment = [
        "T3CODE_HOST=0.0.0.0"
        "T3CODE_PORT=3773"
      ];
      # A GNOME login imports these into the user manager. The display goes away
      # with the session, and the guard flags make the login shell T3 reads PATH
      # from skip the files that set it.
      UnsetEnvironment = [
        "DISPLAY"
        "WAYLAND_DISPLAY"
        "XAUTHORITY"
        "__HM_SESS_VARS_SOURCED"
        "__HM_ZSH_SESS_VARS_SOURCED"
        "__NIXOS_SET_ENVIRONMENT_DONE"
      ];
      # The launcher stops its server child itself on SIGTERM.
      KillMode = "mixed";
      # T3's headless Chrome and tunnels run in this cgroup. When the kernel kills
      # one of them for memory, the server and its agents keep running.
      OOMPolicy = "continue";
      Restart = "always";
      RestartSec = 5;
    };
    Install.WantedBy = [ "default.target" ];
  };
}
