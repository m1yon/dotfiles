{ pkgs, ... }:
{
  virtualisation.docker = {
    enable = true;
    package = pkgs.docker_29;
    rootless.enable = false;
  };

  users.extraGroups.docker.members = [ "michael" ];

  environment.systemPackages = with pkgs; [
    docker_29
    docker-compose
  ];
}
