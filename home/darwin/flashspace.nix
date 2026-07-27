{
  config,
  nixConfigDir,
  ...
}:

{
  home.file.".config/flashspace" = {
    source = config.lib.file.mkOutOfStoreSymlink "${nixConfigDir}/dotfiles/flashspace";
    force = true;
  };

  launchd.agents.flashspace = {
    enable = true;
    config = {
      ProgramArguments = [
        "/usr/bin/open"
        "-g"
        "-j"
        "-a"
        "FlashSpace"
      ];
      ProcessType = "Interactive";
      RunAtLoad = true;
    };
  };
}
