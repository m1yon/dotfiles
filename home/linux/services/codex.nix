{ config, pkgs, ... }:

{
  # The desktop SSH client checks this in the remote login shell before
  # launching its own server. systemd owns the default Codex socket instead.
  home.sessionVariables.CODEX_SSH_SKIP_APP_SERVER_BOOT = "true";

  systemd.user.services.codex-app-server = {
    Unit = {
      Description = "Codex server for desktop SSH connections";
      StartLimitIntervalSec = 60;
      StartLimitBurst = 5;
    };

    Service = {
      # Use the login environment so tools have the same PATH as SSH sessions.
      # The native install also includes the local Code Mode host.
      ExecStart = "${pkgs.zsh}/bin/zsh -lc 'exec ${config.home.homeDirectory}/.local/bin/codex -c features.code_mode_host=true app-server --listen unix://'";
      Environment = [
        "CODEX_HOME=${config.home.homeDirectory}/.codex"
        "PATH=${config.home.profileDirectory}/bin:/run/current-system/sw/bin"
      ];
      WorkingDirectory = config.home.homeDirectory;
      StandardInput = "null";
      Restart = "always";
      RestartSec = 5;
      UMask = "0077";
    };

    Install.WantedBy = [ "default.target" ];
  };
}
