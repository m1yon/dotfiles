{
  pkgs,
  ...
}:
{
  programs.zsh = {
    enable = true;
    shellAliases = {
      cd = "z";
      open = "setsid xdg-open";
      src = "source ~/.zshrc";
    };
  };
}
