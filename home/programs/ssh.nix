{ config, ... }:
{
  sops.secrets.ssh_config = {
    sopsFile = ../../secrets/ssh_config;
    format = "binary";
    path = "${config.home.homeDirectory}/.ssh/config";
  };
}
