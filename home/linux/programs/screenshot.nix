{
  pkgs,
  config,
  ...
}:
{
  home.packages = [
    pkgs.grimblast
    pkgs.satty
    pkgs.wl-clipboard
  ];

  home.activation.createScreenshotsDir = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "${config.home.homeDirectory}/Screenshots"
  '';
}
