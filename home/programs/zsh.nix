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
        rebuild = "nixos-rebuild switch --flake ~/GitHub/dotfiles --use-remote-sudo";
        cd = "z";
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
  };
}
