{
  lib,
  pkgs,
  username,
  homeDirectory,
  ...
}:

let
  symbolicHotKeyValue =
    enabled: charCode: keyCode: modifiers:
    builtins.toJSON {
      inherit enabled;
      value = {
        parameters = [
          charCode
          keyCode
          modifiers
        ];
        type = "standard";
      };
    };

  disabledHotKeyValue = symbolicHotKeyValue false;
  enabledHotKeyValue = symbolicHotKeyValue true;

  screenshotHotKeys = [
    # Screenshot shortcuts in System Settings > Keyboard > Keyboard Shortcuts.
    {
      id = 28;
      value = disabledHotKeyValue 51 20 1179648; # Shift-Command-3
    }
    {
      id = 29;
      value = disabledHotKeyValue 51 20 1441792; # Control-Shift-Command-3
    }
    {
      id = 30;
      value = disabledHotKeyValue 52 21 1179648; # Shift-Command-4
    }
    {
      id = 31;
      value = disabledHotKeyValue 52 21 1441792; # Control-Shift-Command-4
    }
    {
      id = 181;
      value = disabledHotKeyValue 54 22 1179648; # Shift-Command-6, Touch Bar
    }
    {
      id = 182;
      value = disabledHotKeyValue 54 22 1441792; # Control-Shift-Command-6, Touch Bar
    }
    {
      id = 184;
      value = disabledHotKeyValue 53 23 1179648; # Shift-Command-5
    }
  ];

  # Keep macOS's native Control-number Space shortcuts enabled. They provide
  # ordinary switching without Hammerspoon briefly opening Mission Control and
  # are also required by the title-bar drag workaround for moving windows.
  nativeSpaceHotKeys = [
    {
      id = 118;
      value = enabledHotKeyValue 49 18 262144; # Control-1
    }
    {
      id = 119;
      value = enabledHotKeyValue 50 19 262144; # Control-2
    }
    {
      id = 120;
      value = enabledHotKeyValue 51 20 262144; # Control-3
    }
    {
      id = 121;
      value = enabledHotKeyValue 52 21 262144; # Control-4
    }
    {
      id = 122;
      value = enabledHotKeyValue 53 23 262144; # Control-5
    }
    {
      id = 123;
      value = enabledHotKeyValue 54 22 262144; # Control-6
    }
    {
      id = 124;
      value = enabledHotKeyValue 55 26 262144; # Control-7
    }
    {
      id = 125;
      value = enabledHotKeyValue 56 28 262144; # Control-8
    }
    {
      id = 126;
      value = enabledHotKeyValue 57 25 262144; # Control-9
    }
    {
      id = 127;
      value = enabledHotKeyValue 48 29 262144; # Control-0
    }
  ];

  configureSymbolicHotKey = hotKey: ''
    /usr/bin/plutil -remove 'AppleSymbolicHotKeys.${toString hotKey.id}' "$shortcuts_plist" 2>/dev/null || true
    /usr/bin/plutil -insert 'AppleSymbolicHotKeys.${toString hotKey.id}' -json ${lib.escapeShellArg hotKey.value} "$shortcuts_plist"
  '';
in
{
  system.primaryUser = username;
  system.stateVersion = 6;

  users.users.${username} = {
    name = username;
    home = homeDirectory;
    shell = pkgs.zsh;
  };

  programs.zsh.enable = true;
  security = {
    pam.services.sudo_local.touchIdAuth = true;
    sudo.extraConfig = ''
      Defaults:${username} timestamp_type=global
      Defaults:${username} timestamp_timeout=30
    '';
  };

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

  system.keyboard = {
    enableKeyMapping = true;
    swapLeftCommandAndLeftAlt = false;
  };

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

  system.activationScripts.postActivation.text = lib.mkAfter ''
    echo "setting macOS appearance..." >&2
    user=${lib.escapeShellArg username}
    uid="$(id -u -- "$user")"
    if ! launchctl asuser "$uid" sudo --user="$user" -- osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to true'; then
      echo "Unable to refresh the live macOS appearance state; defaults were still written." >&2
    fi

    echo "configuring macOS keyboard shortcuts..." >&2
    shortcuts_plist="$(/usr/bin/mktemp -t dotfiles-symbolichotkeys)"
    if launchctl asuser "$uid" sudo --user="$user" -- defaults export com.apple.symbolichotkeys - > "$shortcuts_plist"; then
      ${lib.concatMapStringsSep "\n" configureSymbolicHotKey (screenshotHotKeys ++ nativeSpaceHotKeys)}
      launchctl asuser "$uid" sudo --user="$user" -- defaults import com.apple.symbolichotkeys - < "$shortcuts_plist"
      # Refresh the per-user preference cache and shortcut consumers.
      launchctl asuser "$uid" sudo --user="$user" -- /usr/bin/killall cfprefsd 2>/dev/null || true
      /bin/sleep 1
      launchctl asuser "$uid" sudo --user="$user" -- /usr/bin/killall SystemUIServer 2>/dev/null || true
      launchctl asuser "$uid" sudo --user="$user" -- /usr/bin/killall Dock 2>/dev/null || true
    else
      echo "Unable to export macOS keyboard shortcuts; leaving them unchanged." >&2
    fi
    /bin/rm -f "$shortcuts_plist"
  '';

  system.defaults = {
    CustomUserPreferences."com.apple.dock" = {
      # Follow an app to the native Space containing its windows.
      "workspaces-auto-swoosh" = true;
    };

    dock = {
      autohide = true;
      expose-group-apps = true;
      mru-spaces = false;
      persistent-apps = [
        "/Applications/Google Chrome.app"
        "/Applications/Ghostty.app"
      ];
      show-recents = false;
    };

    spaces = {
      spans-displays = true;
    };

    finder = {
      AppleShowAllExtensions = false;
      FXPreferredViewStyle = "clmv";
    };

    WindowManager = {
      StandardHideWidgets = true;
    };

    NSGlobalDomain = {
      AppleShowAllExtensions = false;
      AppleInterfaceStyle = "Dark";
      AppleInterfaceStyleSwitchesAutomatically = false;
      NSDocumentSaveNewDocumentsToCloud = false;
    };
  };
}
