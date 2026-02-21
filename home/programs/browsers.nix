{
  pkgs,
  config,
  username,
  ...
}: {
  programs = {
    google-chrome = {
      enable = true;
    };
  };
}
