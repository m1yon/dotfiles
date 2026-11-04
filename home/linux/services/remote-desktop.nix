{
  config,
  lib,
  pkgs,
  username,
  hostname,
  ...
}:

let
  tlsDir = "${config.xdg.dataHome}/gnome-remote-desktop";
  tlsCert = "${tlsDir}/rdp-tls.crt";
  tlsKey = "${tlsDir}/rdp-tls.key";

  # grdctl reads the password from stdin when it is omitted, which keeps it out of ps.
  setup = pkgs.writeShellApplication {
    name = "gnome-remote-desktop-credentials";
    runtimeInputs = [
      pkgs.gnome-remote-desktop
      pkgs.openssl
      pkgs.coreutils
    ];
    text = ''
      mkdir -p "${tlsDir}"
      if [ ! -s "${tlsKey}" ] || [ ! -s "${tlsCert}" ]; then
        openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 \
          -subj /CN=${hostname} -out "${tlsCert}" -keyout "${tlsKey}"
      fi
      grdctl rdp set-credentials ${username} < ${config.sops.secrets.rdp_password.path}
    '';
  };
in
{
  sops.secrets.rdp_password.sopsFile = ../../../secrets/remote-desktop.yaml;

  dconf.settings."org/gnome/desktop/remote-desktop/rdp" = {
    enable = true;
    view-only = false;
    screen-share-mode = "extend";
    tls-cert = tlsCert;
    tls-key = tlsKey;
  };

  systemd.user.services.gnome-remote-desktop-credentials = {
    Unit = {
      Description = "Set RDP credentials in the unlocked login keyring";
      After = [ "sops-nix.service" ];
      Before = [ "gnome-remote-desktop.service" ];
      Wants = [ "gnome-remote-desktop.service" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = lib.getExe setup;
    };
    Install.WantedBy = [ "gnome-session.target" ];
  };
}
