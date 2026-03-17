{ config, pkgs, ... }:
{
  home.packages = with pkgs; [
    docker
    docker-compose
  ];

  # Docker CLI configuration
  home.sessionVariables = {
    DOCKER_CONFIG = "${config.xdg.configHome}/docker";
  };
}
