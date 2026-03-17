{ pkgs, ... }:
{
  virtualisation.docker.enable = true;
  virtualisation.docker.rootless.enable = false;

  users.extraGroups.docker.members = [ "michael" ];

  environment.systemPackages = with pkgs; [
    docker
    docker-compose
  ];
}
