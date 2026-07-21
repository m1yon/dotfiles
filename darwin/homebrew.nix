{
  config,
  inputs,
  username,
  ...
}:

{
  imports = [
    inputs.nix-homebrew.darwinModules.nix-homebrew
  ];

  nix-homebrew = {
    enable = true;
    user = username;
    mutableTaps = false;
    taps = {
      "homebrew/homebrew-core" = inputs.homebrew-core;
      "homebrew/homebrew-cask" = inputs.homebrew-cask;
    };
  };

  homebrew = {
    enable = true;
    taps = builtins.attrNames config.nix-homebrew.taps;

    onActivation = {
      autoUpdate = true;
      upgrade = true;
      # nix-darwin's cleanup modes still pass Homebrew's deprecated --cleanup flag.
      cleanup = "none";
      extraFlags = [
        "--force-cleanup"
        "--zap"
      ];
    };

    brews = [
      "mas"
    ];
    casks = [
      "anki"
      "cleanshot"
      "codex-app"
      "discord"
      "display-pilot"
      "ghostty"
      "google-chrome"
      "grammarly-desktop"
      "hammerspoon"
      "linear"
      "linearmouse"
      "microsoft-excel"
      "microsoft-teams"
      "microsoft-word"
      "obsidian"
      "rectangle-pro"
      "slack"
      "spotify"
      "superhuman"
      "superwhisper"
      "todoist-app"
      "bruno"
    ];
    masApps = {
      "ScreenZen" = 1541027222;
    };
  };
}
