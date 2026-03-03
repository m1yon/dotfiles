{ config, pkgs, ... }:
{
  home.packages = [ pkgs.sops ];

  sops = {
    age.sshKeyPaths = [ "${config.home.homeDirectory}/.ssh/id_ed25519" ];
  };
}
