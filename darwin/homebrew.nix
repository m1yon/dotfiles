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

    brews = [ ];
    casks = [
      "cleanshot"
      "codex-app"
      "discord"
      "ghostty"
      "google-chrome"
      "grammarly-desktop"
      "linear"
      "linearmouse"
      "microsoft-teams"
      "obsidian"
      "slack"
      "spotify"
      "superhuman"
      "superwhisper"
      "todoist-app"
    ];
    masApps = { };
  };
}
