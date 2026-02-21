{
  pkgs,
  ...
}: {
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
  };
}
