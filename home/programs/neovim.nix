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
      vtsls
      taplo
      golangci-lint
      gofumpt
      gotools
      golines
      prettierd
      stylua
      ruff
    ];
  };

  home.file = {
    ".config/nvim/".source = outOfStore "${dotfiles}/nvim";
  };
}
