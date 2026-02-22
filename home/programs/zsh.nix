{
  pkgs,
  config,
  username,
  ...
}: {
  programs = {
    zsh = {
      enable = true;
       shellAliases = {
        lg = "lazygit";
      };
    };
  };
}
