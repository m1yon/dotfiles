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

  # FreeRDP 3.32.0 and 3.32.1 send the early auth result before reading the client's
  # credentials, which hangs Windows App for macOS at "Securing connection".
  # https://github.com/FreeRDP/FreeRDP/issues/13549
  remoteDesktop = pkgs.gnome-remote-desktop.override {
    freerdp = pkgs.freerdp.overrideAttrs (old: {
      patches =
        (old.patches or [ ])
        ++ lib.optional (lib.versionOlder old.version "3.32.2") (
          pkgs.fetchpatch {
            url = "https://github.com/FreeRDP/FreeRDP/commit/cbb6a73d1281fa9e4084c24f07ed0c9ad171f125.patch";
            hash = "sha256-TepDYv+GZlE45Vb9TMjPFPhrGKKWPi49VKggN5vAvEE=";
          }
        );
    });
  };

  # grdctl reads the password from stdin when it is omitted, which keeps it out of ps.
  setup = pkgs.writeShellApplication {
    name = "gnome-remote-desktop-credentials";
    runtimeInputs = [
      remoteDesktop
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

  # GNOME's module installs the unit, so this replaces only its ExecStart. Settings and
  # Connections keep the stock package and do not rebuild.
  #
  # Windows App for macOS disconnects with error 0x200d on H.264 from this AMD encoder. Naming a
  # VA-API driver that does not exist makes the daemon fall back to its software codec.
  xdg.configFile."systemd/user/gnome-remote-desktop.service.d/override.conf".text = ''
    [Service]
    ExecStart=
    ExecStart=${remoteDesktop}/libexec/gnome-remote-desktop-daemon
    Environment=LIBVA_DRIVER_NAME=none
  '';

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
