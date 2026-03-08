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
  colors = config.lib.stylix.colors.withHashtag;
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
    ".local/share/nvim/stylix-base16.lua".text = ''
      return {
        base00 = "${colors.base00}",
        base01 = "${colors.base01}",
        base02 = "${colors.base02}",
        base03 = "${colors.base03}",
        base04 = "${colors.base04}",
        base05 = "${colors.base05}",
        base06 = "${colors.base06}",
        base07 = "${colors.base07}",
        base08 = "${colors.base08}",
        base09 = "${colors.base09}",
        base0A = "${colors.base0A}",
        base0B = "${colors.base0B}",
        base0C = "${colors.base0C}",
        base0D = "${colors.base0D}",
        base0E = "${colors.base0E}",
        base0F = "${colors.base0F}",
      }
    '';
  };
}
