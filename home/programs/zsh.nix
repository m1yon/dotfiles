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
      };
    };
    starship = {
        enable = true;
      };
  };
}
