{
  config,
  ...
}:
{
  services.flameshot = {
    enable = true;
    settings = {
      General = {
        contrastOpacity = 188;
        savePath = "${config.home.homeDirectory}/Screenshots";
        showAbortNotification = false;
        showDesktopNotification = false;
        showHelp = false;
        showSidePanelButton = false;
        showStartupLaunchMessage = false;
        startupLaunch = true;
        useGrimAdapter = true;
      };
    };
  };
}
