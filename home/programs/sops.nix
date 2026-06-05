{ config, pkgs, ... }:
{
  home.packages = [ pkgs.sops ];

  sops = {
    age.sshKeyPaths = [ "${config.home.homeDirectory}/.ssh/id_ed25519" ];
  };

  sops.secrets = {
    xero_client_id.sopsFile = ../../secrets/xero.yaml;
    xero_client_secret.sopsFile = ../../secrets/xero.yaml;
  };
}
