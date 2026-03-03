{
  pkgs,
  ...
}:
{
  programs.gpg = {
    enable = true;
  };

  services.gpg-agent = {
    enable = true;
    defaultCacheTtl = 3600;
    maxCacheTtl = 7200;
    pinentry.package = pkgs.pinentry-gnome3;
    enableSshSupport = false;
    enableZshIntegration = true;
  };
}
