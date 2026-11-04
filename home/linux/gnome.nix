{
  lib,
  pkgs,
  nixConfigDir,
  ...
}:

let
  # Mutter keeps a closed panel lit when it is the only display and idle blanking
  # is off. It can relight the panel on a monitor change, so this polls.
  panelOff = pkgs.writeShellApplication {
    name = "panel-off-when-lid-closed";
    runtimeInputs = [
      pkgs.systemd
      pkgs.coreutils
    ];
    bashOptions = [
      "nounset"
      "pipefail"
    ];
    text = ''
      login1() {
        busctl --system get-property org.freedesktop.login1 /org/freedesktop/login1 \
          org.freedesktop.login1.Manager "$1" | cut -d' ' -f2
      }
      set_panel() {
        busctl --user set-property org.gnome.Mutter.DisplayConfig /org/gnome/Mutter/DisplayConfig \
          org.gnome.Mutter.DisplayConfig PowerSaveMode i "$1"
      }
      was_off=false
      while sleep 5; do
        if [ "$(login1 LidClosed)" = true ] && [ "$(login1 Docked)" = false ]; then
          set_panel 3
          was_off=true
        elif [ "$was_off" = true ]; then
          set_panel 0
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
    "org/gnome/settings-daemon/plugins/power".sleep-inactive-ac-type = "nothing";
  };

  systemd.user.services.panel-off-when-lid-closed = {
    Unit = {
      Description = "Turn the laptop panel off while the lid is closed";
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = lib.getExe panelOff;
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install.WantedBy = [ "gnome-session.target" ];
  };
}
