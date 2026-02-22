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
        src = "source ~/.zshrc";
        update-opencode = "nix flake update opencode --flake ~/GitHub/dotfiles && rebuild";
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
    foot = {
        enable = true;
    };
  };
}
