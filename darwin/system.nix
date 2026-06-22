{
  lib,
  pkgs,
  username,
  homeDirectory,
  ...
}:

{
  system.primaryUser = username;
  system.stateVersion = 6;

  users.users.${username} = {
    name = username;
    home = homeDirectory;
    shell = pkgs.zsh;
  };

  programs.zsh.enable = true;
  security.pam.services.sudo_local.touchIdAuth = true;

  power = {
    sleep = {
      computer = "never";
      display = "never";
      harddisk = "never";
      allowSleepByPowerButton = false;
    };

    restartAfterFreeze = true;
  };

  system.activationScripts.power.text = lib.mkAfter ''
    setPmset() {
      if ! /usr/bin/pmset -a "$@"; then
        echo "pmset $* is not supported on this Mac; skipping." >&2
      fi
    }

    setPmset hibernatemode 0
    setPmset standby 0
    setPmset autopoweroff 0
    setPmset powermode 2
  '';

  system.defaults = {
    dock = {
      autohide = true;
      persistent-apps = [
        "/Applications/Google Chrome.app"
        "/Applications/Ghostty.app"
      ];
      show-recents = false;
    };

    finder = {
      AppleShowAllExtensions = true;
      FXPreferredViewStyle = "clmv";
    };

    WindowManager = {
      StandardHideWidgets = true;
    };

    NSGlobalDomain = {
      AppleShowAllExtensions = true;
      AppleInterfaceStyle = "Dark";
      AppleInterfaceStyleSwitchesAutomatically = false;
      NSDocumentSaveNewDocumentsToCloud = false;
    };
  };
}
