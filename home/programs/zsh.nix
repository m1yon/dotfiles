{
  pkgs,
  config,
  username,
  ...
}:
{
  programs = {
    zsh = {
      enable = true;
      shellAliases = {
        lg = "lazygit";
        cd = "z";
        src = "source ~/.zshrc";
      };
    };
    starship = {
      enable = true;
    };
    zoxide = {
      enable = true;
    };
    atuin = {
      enable = true;
    };
    eza = {
      enable = true;
    };
    fzf = {
      enable = true;
      enableZshIntegration = true;
    };
    yazi = {
      enable = true;
    };
  };
}
