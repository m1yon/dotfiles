{ pkgs, ... }:
{
  virtualisation.docker = {
    enable = true;
    package = pkgs.docker_29;
    rootless.enable = false;
    enableOnBoot = false;
  };

  users.extraGroups.docker.members = [ "michael" ];
}
