{
  config,
  lib,
  pkgs,
  ...
}:

let
  appImage = "${config.xdg.dataHome}/t3code/T3-Code.AppImage";

  icon = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/pingdotgg/t3code/2359643cffa6ba9ee84d6f2694b935de54a8013e/assets/prod/black-universal-1024.png";
    hash = "sha256-QD6HRVb/vs7o0bK11hKodDA/rHkSEqJhuzvRtx2D540=";
  };

  # T3 Code's updater replaces the file named by $APPIMAGE, which appimage-run
  # sets. The name has no version in it, so updates overwrite this same path.
  t3code = pkgs.writeShellApplication {
    name = "t3code";
    runtimeInputs = with pkgs; [
      appimage-run
      coreutils
      curl
      findutils
      gawk
      procps
    ];
    text = ''
      app=${appImage}

      if [ ! -x "$app" ]; then
        feed=https://github.com/pingdotgg/t3code/releases/latest/download
        manifest="$(curl -fsSL "$feed/latest-linux.yml")"
        file="$(awk '/^path:/ { print $2 }' <<<"$manifest")"
        expected="$(awk '/^sha512:/ { print $2 }' <<<"$manifest" | base64 -d | od -An -tx1 | tr -d ' \n')"

        mkdir -p "$(dirname "$app")"
        tmp="$(mktemp -p "$(dirname "$app")")"
        trap 'rm -f "$tmp"' EXIT
        curl -fsSL -o "$tmp" "$feed/$file"
        echo "$expected  $tmp" | sha512sum --check --quiet
        chmod 755 "$tmp"
        mv "$tmp" "$app"
        trap - EXIT
      fi

      # appimage-run unpacks each version into its own cache directory. Clear
      # out old versions, but only while no unpacked copy is running.
      cache="''${XDG_CACHE_HOME:-$HOME/.cache}/appimage-run"
      if [ -d "$cache" ] && ! pgrep -f "$cache/" >/dev/null; then
        current="$(sha256sum "$app" | cut -d' ' -f1)"
        find "$cache" -mindepth 1 -maxdepth 1 ! -name "$current" -exec rm -rf {} +
      fi

      # GNOME's session exports home-manager's sourced flag without the PATH
      # entries it guards. T3 Code reads PATH from a login shell, which skips
      # hm-session-vars.sh while the flag is set, so claude goes missing.
      unset __HM_SESS_VARS_SOURCED

      export CHROME_DESKTOP=t3code.desktop
      exec appimage-run "$app" "$@"
    '';
  };

  # Chromium moves T3 Code's main process into its own scope, so a copy started
  # outside this unit (the updater's relaunch, the app grid) outlives it, and a
  # second copy would quit on the single-instance lock. Wait for the running copy
  # instead, and Restart=always then starts a supervised one. A copy's bwrap
  # command line ends with the AppImage path. The t3 CLI's adds --appimage-*.
  t3code-service = pkgs.writeShellApplication {
    name = "t3code-service";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.procps
      t3code
    ];
    text = ''
      if running="$(pgrep -o -u "$(id -u)" -f -- ${lib.escapeShellArg "^/nix/store/[^ ]*/bin/bwrap .*${lib.escapeRegex appImage}( --no-sandbox)?$"})"; then
        exec tail --pid="$running" -f /dev/null
      fi

      exec t3code --no-sandbox
    '';
  };
in
{
  home.packages = [ t3code ];

  xdg.desktopEntries.t3code = {
    name = "T3 Code";
    comment = "T3 Code desktop build";
    exec = "t3code --no-sandbox %U";
    icon = "${icon}";
    terminal = false;
    categories = [ "Development" ];
    settings.StartupWMClass = "com.t3tools.T3Code";
  };

  systemd.user.services.t3code = {
    Unit = {
      Description = "T3 Code";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
      # Agents run `task rebuild` from inside T3 Code, so a switch must not
      # restart it under them.
      X-SwitchMethod = "keep-old";
    };
    Service = {
      ExecStart = lib.getExe t3code-service;
      Restart = "always";
      RestartSec = 5;
    };
    Install.WantedBy = [ "gnome-session.target" ];
  };
}
