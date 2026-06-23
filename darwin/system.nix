{
  lib,
  pkgs,
  username,
  homeDirectory,
  ...
}:

let
  spotlightItem = enabled: name: {
    inherit enabled name;
  };

  disabledHotKeyValue =
    charCode: keyCode: modifiers:
    "{ enabled = 0; value = { parameters = (${toString charCode}, ${toString keyCode}, ${toString modifiers}); type = standard; }; }";

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

  disableScreenshotHotKey =
    hotKey:
    "launchctl asuser \"$uid\" sudo --user=\"$user\" -- defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add ${toString hotKey.id} ${lib.escapeShellArg hotKey.value}";
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
  security.pam.services.sudo_local.touchIdAuth = true;

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
  '';

  system.activationScripts.disableScreenshotShortcuts.text = lib.mkAfter ''
    echo "disabling macOS screenshot shortcuts..." >&2
    user=${lib.escapeShellArg username}
    uid="$(id -u -- "$user")"
    ${lib.concatMapStringsSep "\n" disableScreenshotHotKey screenshotHotKeys}
  '';

  system.defaults = {
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
      AppleShowAllExtensions = true;
      FXPreferredViewStyle = "clmv";
    };

    WindowManager = {
      StandardHideWidgets = true;
    };

    CustomUserPreferences = {
      "com.apple.spotlight" = {
        # Show apps and web results, but keep local files/data out of Spotlight.
        orderedItems =
          (map (spotlightItem true) [
            "APPLICATIONS"
            "MENU_WEBSEARCH"
            "MENU_SPOTLIGHT_SUGGESTIONS"
          ])
          ++ (map (spotlightItem false) [
            "MENU_CONVERSION"
            "MENU_EXPRESSION"
            "MENU_DEFINITION"
            "SYSTEM_PREFS"
            "DOCUMENTS"
            "DIRECTORIES"
            "PRESENTATIONS"
            "SPREADSHEETS"
            "PDF"
            "MESSAGES"
            "CONTACT"
            "EVENT_TODO"
            "IMAGES"
            "BOOKMARKS"
            "MUSIC"
            "MOVIES"
            "FONTS"
            "MENU_OTHER"
          ]);
        parsecEnabled = true;
      };
    };

    NSGlobalDomain = {
      AppleShowAllExtensions = true;
      AppleInterfaceStyle = "Dark";
      AppleInterfaceStyleSwitchesAutomatically = false;
      NSDocumentSaveNewDocumentsToCloud = false;
    };
  };
}
