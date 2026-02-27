{ config, pkgs, inputs, ... }:

let
  dotfiles = "/home/michael/GitHub/dotfiles/dotfiles";
  outOfStore = config.lib.file.mkOutOfStoreSymlink;
in
{
  home.packages = [
    inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.opencode
  ];

  home.file = {
    ".config/opencode/".source = outOfStore "${dotfiles}/opencode";
  };
}
