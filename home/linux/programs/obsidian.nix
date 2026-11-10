{ lib, pkgs, ... }:

{
  home.packages = with pkgs; [
    obsidian
  ];

  # The obsidian CLI needs the app running. Restart it after a crash or a close.
  systemd.user.services.obsidian = {
    Unit = {
      Description = "Obsidian";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = lib.getExe pkgs.obsidian;
      Restart = "always";
      RestartSec = 5;
    };
    Install.WantedBy = [ "gnome-session.target" ];
  };
}
