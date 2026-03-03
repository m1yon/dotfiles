{
  pkgs,
  ...
}:
{
  programs.zsh = {
    enable = true;
    shellAliases = {
      cd = "z";
      src = "source ~/.zshrc";
    };
  };
}
