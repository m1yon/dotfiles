{
  lib,
  pkgs,
  nixConfigDir,
  ...
}:

let
  # Mutter keeps a closed panel lit when it is the only display and idle blanking
  # is off. It can relight the panel on a monitor change, so this polls.
  closedLidSession = pkgs.writeShellApplication {
    name = "closed-lid-session";
    runtimeInputs = [
      pkgs.systemd
      pkgs.coreutils
      pkgs.gnugrep
    ];
    bashOptions = [
      "nounset"
      "pipefail"
    ];
    text = ''
      lid_closed() {
        [ "$(busctl --system get-property org.freedesktop.login1 /org/freedesktop/login1 \
          org.freedesktop.login1.Manager LidClosed)" = "b true" ]
      }
      # Not logind's Docked, which counts only enabled connectors. PowerSaveMode 3
      # disables them all, so Docked never sees a monitor plugged in while it is set.
      external_display() {
        grep -qsx connected /sys/class/drm/card*-{DP,HDMI}-*/status
      }
      set_panel() {
        busctl --user set-property org.gnome.Mutter.DisplayConfig /org/gnome/Mutter/DisplayConfig \
          org.gnome.Mutter.DisplayConfig PowerSaveMode i "$1"
      }
      screensaver() {
        busctl --user call org.gnome.ScreenSaver /org/gnome/ScreenSaver org.gnome.ScreenSaver "$@"
      }
      session_locked() {
        [ "$(busctl --system get-property org.freedesktop.login1 /org/freedesktop/login1/session/auto \
          org.freedesktop.login1.Session LockedHint)" = "b true" ]
      }
      was_off=false
      while sleep 5; do
        if lid_closed && ! external_display; then
          set_panel 3
          was_off=true
          # gsd-power raises the shield when the lid closes while an app inhibits suspend,
          # as Chrome does while it plays audio. No setting controls this. A real lock stays.
          if [ "$(screensaver GetActive)" = "b true" ] && ! session_locked; then
            screensaver SetActive b false
          fi
        elif [ "$was_off" = true ]; then
          set_panel 0
          screensaver() {
        busctl --user call org.gnome.ScreenSaver /org/gnome/ScreenSaver org.gnome.ScreenSaver "$@"
      }
      session_locked() {
        [ "$(busctl --system get-property org.freedesktop.login1 /org/freedesktop/login1/session/auto \
          org.freedesktop.login1.Session LockedHint)" = "b true" ]
      }
      was_off=false
        fi
      done
    '';
  };
in
{
  dconf.settings = {
    "org/gnome/desktop/background" = {
      picture-uri = "file://${nixConfigDir}/wallpapers/sky-grass.jpg";
      picture-uri-dark = "file://${nixConfigDir}/wallpapers/sky-grass.jpg";
    };
    # GNOME Shell cuts RDP and screen capture while its shield is up, and the idle
    # blank raises the shield even with locking off. This session has to stay reachable.
    "org/gnome/desktop/screensaver".lock-enabled = false;
    "org/gnome/desktop/session".idle-delay = lib.hm.gvariant.mkUint32 0;
    "org/gnome/settings-daemon/plugins/power" = {
      sleep-inactive-ac-type = "nothing";
      sleep-inactive-battery-type = "nothing";
    };
  };

  systemd.user.services.closed-lid-session = {
    Unit = {
      Description = "Keep the closed-lid session dark and reachable";
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = lib.getExe closedLidSession;
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install.WantedBy = [ "gnome-session.target" ];
  };
}
