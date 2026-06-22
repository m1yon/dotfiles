{
  config,
  ...
}:

{
  sops.secrets.opencode_web_ui_password.sopsFile = ../../../secrets/opencode-web.yaml;

  sops.templates."opencode-web-env" = {
    path = "${config.xdg.configHome}/opencode/env";
    content = ''
      OPENCODE_SERVER_PASSWORD=${config.sops.placeholder.opencode_web_ui_password}
    '';
  };

  systemd.user.services.opencode-web = {
    Unit = {
      Description = "OpenCode web UI";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
      StartLimitIntervalSec = 60;
      StartLimitBurst = 3;
    };
    Service = {
      EnvironmentFile = config.sops.templates."opencode-web-env".path;
      ExecStart = "${config.home.profileDirectory}/bin/opencode web --hostname 127.0.0.1 --port 41823";
      Restart = "on-failure";
      RestartSec = 10;
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
