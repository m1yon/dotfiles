{
  config,
  lib,
  pkgs,
  ...
}:
let
  tokenFile = config.sops.secrets.todoist_api_token.path;
in
{
  # Agents run td from shells that never read .zshrc, so td reads its own token.
  # An exported token would also reach every other process those shells start.
  home.packages = [
    (pkgs.writeShellApplication {
      name = "td";
      text = ''
        if [ -z "''${TODOIST_API_TOKEN:-}" ] && [ -r "${tokenFile}" ]; then
          TODOIST_API_TOKEN=$(<"${tokenFile}")
          export TODOIST_API_TOKEN
        fi
        exec ${lib.getExe (pkgs.callPackage ../pkgs/todoist-cli { })} "$@"
      '';
    })
  ];

  sops.secrets = {
    todoist_api_token.sopsFile = ../../../secrets/todoist.yaml;
  };
}
