{
  config,
  pkgs,
  ...
}:

let
  configDir = "${config.xdg.configHome}/cloudflared";
  tunnelId = "38b0c0a5-6efb-4166-a6ec-6d32eda50a28";
  hostname = "control.meca-ai.com";
  localPort = 41823;
in
{
  home.packages = [ pkgs.cloudflared ];

  sops.secrets.cloudflared_credentials_json.sopsFile = ../../secrets/cloudflared.yaml;

  sops.templates."cloudflared-credentials.json" = {
    path = "${configDir}/credentials.json";
    content = config.sops.placeholder.cloudflared_credentials_json;
  };

  sops.templates."cloudflared-config.yml" = {
    path = "${configDir}/config.yml";
    content = ''
      tunnel: ${tunnelId}
      credentials-file: ${configDir}/credentials.json

      ingress:
        - hostname: ${hostname}
          service: http://localhost:${toString localPort}
        - service: http_status:404
    '';
  };

  systemd.user.services.cloudflared = {
    Unit = {
      Description = "Cloudflare Tunnel";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
      StartLimitIntervalSec = 60;
      StartLimitBurst = 3;
    };
    Service = {
      ExecStart = "${pkgs.cloudflared}/bin/cloudflared tunnel --config ${configDir}/config.yml --no-autoupdate run";
      Restart = "on-failure";
      RestartSec = 10;
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
