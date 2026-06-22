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
  prettyTsErrorsPackageLock = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/hexh250786313/pretty-ts-errors/4d4a167d4cc9bd6c07945c89441b154746e2b2d6/package-lock.json";
    hash = "sha256-9+sJi7tXqJ5hfQS9vDLRZrIlyeL5p/lIkfEUBJ7Mtqc=";
  };
  prettyTsErrorsMarkdown = pkgs.buildNpmPackage rec {
    pname = "pretty-ts-errors-markdown";
    version = "0.0.15";
    src = pkgs.fetchurl {
      url = "https://registry.npmjs.org/pretty-ts-errors-markdown/-/pretty-ts-errors-markdown-${version}.tgz";
      hash = "sha256-MrT0FwrjAEOuct4Ogm8cpjysKl1HPl38URRBKFCt0ow=";
    };
    postPatch = ''
      cp ${prettyTsErrorsPackageLock} package-lock.json
    '';
    npmDepsHash = "sha256-aC+t2FYWJgDzXmfYg2IDJ7W2pLPAZ1o3TC68MWZhbSg=";
    dontNpmBuild = true;
    npmInstallFlags = [ "--omit=dev" ];
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
      nodejs
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
      ripgrep
      prettierd
      stylua
      ruff
      imagemagick
      prettyTsErrorsMarkdown
    ];
  };

  home.file = {
    ".config/nvim/".source = outOfStore "${dotfiles}/nvim";
  };
}
