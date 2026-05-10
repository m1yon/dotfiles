{
  config,
  ...
}:

{
  sops.secrets.openchamber_ui_password.sopsFile = ../../secrets/openchamber.yaml;

  sops.templates."openchamber-env" = {
    path = "${config.xdg.configHome}/openchamber/env";
    content = ''
      OPENCHAMBER_UI_PASSWORD=${config.sops.placeholder.openchamber_ui_password}
    '';
  };

  systemd.user.services.openchamber = {
    Unit = {
      Description = "OpenChamber web UI";
      After = [
        "network-online.target"
        "sops-nix.service"
      ];
      Wants = [ "network-online.target" ];
      Requires = [ "sops-nix.service" ];
      StartLimitIntervalSec = 60;
      StartLimitBurst = 3;
    };
    Service = {
      EnvironmentFile = config.sops.templates."openchamber-env".path;
      ExecStart = "${config.home.profileDirectory}/bin/openchamber serve --foreground --host 127.0.0.1 --port 41823";
      Restart = "on-failure";
      RestartSec = 10;
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
