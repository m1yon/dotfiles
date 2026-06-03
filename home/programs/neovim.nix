{
  config,
  pkgs,
  inputs,
  nixConfigDir,
  ...
}:

let
  dotfiles = "${nixConfigDir}/dotfiles";
  outOfStore = config.lib.file.mkOutOfStoreSymlink;
  unstablePkgs = import inputs.nixpkgs-unstable {
    system = pkgs.stdenv.hostPlatform.system;
    config.allowUnfree = true;
  };
in
{
  imports = [
    inputs.nix-wrapper-modules.homeModules.neovim
  ];

  wrappers.neovim = {
    enable = true;
    extraPackages = with pkgs; [
      gcc
      gopls
      lua-language-server
      basedpyright
      terraform-ls
      yaml-language-server
      tailwindcss-language-server
      vscode-langservers-extracted
      unstablePkgs.typescript-go
      taplo
      nixd
      golangci-lint
      gofumpt
      gotools
      golines
      prettierd
      stylua
      ruff
      imagemagick
    ];
  };

  home.file = {
    ".config/nvim/".source = outOfStore "${dotfiles}/nvim";
  };
}
