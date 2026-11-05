{ config, pkgs, ... }:
{
  home.packages = [ (pkgs.callPackage ../pkgs/todoist-cli { }) ];

  sops.secrets = {
    todoist_api_token.sopsFile = ../../../secrets/todoist.yaml;
  };

  sops.templates."todoist-env" = {
    content = ''
      export TODOIST_API_TOKEN="${config.sops.placeholder.todoist_api_token}"
    '';
  };

  programs.zsh.initContent = ''
    [ -f "${config.sops.templates."todoist-env".path}" ] && source "${
      config.sops.templates."todoist-env".path
    }"
  '';
}
