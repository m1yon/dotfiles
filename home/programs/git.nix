{
  pkgs,
  ...
}:
{
  programs.gh = {
    enable = true;
    gitCredentialHelper = {
      enable = true;
    };
  };

  programs.delta = {
    enable = true;
  };

  programs.git = {
    enable = true;
    settings.user.name = "Michael Lyon";
    settings.user.email = "mlyon360@gmail.com";
  };
}
