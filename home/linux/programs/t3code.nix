{ config, pkgs, ... }:

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

      export CHROME_DESKTOP=t3code.desktop
      exec appimage-run "$app" "$@"
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
    settings.StartupWMClass = "t3-code-desktop";
  };
}
