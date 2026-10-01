{
  config,
  lib,
  pkgs,
  ...
}:

let
  environment = {
    SENTRY_ORG = "meca-therapies";
    SENTRY_PROJECT = "cd-documents";
    SENTRY_BASE_URL = "https://sentry.io";
  };
  tokenFile = "${config.home.homeDirectory}/.config/sentry/auth-token";

  loadEnvironment = pkgs.writeText "sentry-environment.sh" ''
    ${lib.concatStringsSep "\n" (
      lib.mapAttrsToList (name: value: "export ${name}=${lib.escapeShellArg value}") environment
    )}

    if [ -r ${lib.escapeShellArg tokenFile} ] && [ -s ${lib.escapeShellArg tokenFile} ] &&
      SENTRY_AUTH_TOKEN="$(/bin/cat ${lib.escapeShellArg tokenFile})" && [ -n "$SENTRY_AUTH_TOKEN" ]; then
      export SENTRY_AUTH_TOKEN
    else
      unset SENTRY_AUTH_TOKEN
    fi
  '';

  refreshEnvironment = pkgs.writeShellScriptBin "sentry-refresh" ''
    set -e
    . ${loadEnvironment}

    ${lib.concatStringsSep "\n" (
      lib.mapAttrsToList (
        name: _: "/bin/launchctl setenv ${lib.escapeShellArg name} \"$" + name + "\""
      ) environment
    )}

    if [ -n "''${SENTRY_AUTH_TOKEN:-}" ]; then
      /bin/launchctl setenv SENTRY_AUTH_TOKEN "$SENTRY_AUTH_TOKEN"
    else
      /bin/launchctl unsetenv SENTRY_AUTH_TOKEN
    fi
  '';
in
{
  home.packages = [ refreshEnvironment ];

  programs.zsh.envExtra = ''
    . ${loadEnvironment}
  '';

  launchd.agents.sentry-environment = {
    enable = true;
    config = {
      ProgramArguments = [ (lib.getExe refreshEnvironment) ];
      RunAtLoad = true;
    };
  };

  home.activation.sentryEnvironment = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${lib.getExe refreshEnvironment}
  '';
}
