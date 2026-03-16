{
  config,
  pkgs,
  ...
}:

let
  homeDir = config.home.homeDirectory;
  carecoordinatorsConfigDir = "${homeDir}/.config/onedrive-carecoordinators";
  personalConfigDir = "${homeDir}/.config/onedrive-personal";

  mkOnedriveService = { description, confdir }: {
    Unit = {
      Description = "OneDrive sync - ${description}";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
      StartLimitIntervalSec = 60;
      StartLimitBurst = 3;
    };
    Service = {
      ExecStart = "${pkgs.onedrive}/bin/onedrive --monitor --confdir=${confdir}";
      Restart = "on-failure";
      RestartSec = 10;
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
in
{
  home.packages = [ pkgs.onedrive ];

  # Decrypt OneDrive secrets from sops
  sops.secrets = {
    onedrive_sharepoint_drive_id.sopsFile = ../../secrets/onedrive.yaml;
    azure_tenant_id.sopsFile = ../../secrets/onedrive.yaml;
  };

  # Personal OneDrive config (no secrets needed)
  home.file."${personalConfigDir}/config" = {
    text = ''
      # Personal OneDrive
      sync_dir = "~/OneDrive/personal"
      skip_dotfiles = "true"
      skip_symlinks = "true"
      monitor_interval = "300"
    '';
  };

  # SharePoint config via sops template (contains drive_id secret)
  sops.templates."onedrive-carecoordinators-config" = {
    path = "${carecoordinatorsConfigDir}/config";
    content = ''
      # SharePoint - Care Coordinators
      sync_dir = "~/OneDrive/carecoordinators"
      drive_id = "${config.sops.placeholder.onedrive_sharepoint_drive_id}"
      skip_dotfiles = "true"
      skip_symlinks = "true"
      monitor_interval = "300"
    '';
  };

  systemd.user.services.onedrive-personal = mkOnedriveService {
    description = "Personal";
    confdir = personalConfigDir;
  };

  systemd.user.services.onedrive-carecoordinators = mkOnedriveService {
    description = "SharePoint Care Coordinators";
    confdir = carecoordinatorsConfigDir;
  };
}
