{
  lib,
  pkgs,
  inputs,
  ...
}:
{
  home.packages = lib.optionals pkgs.stdenv.hostPlatform.isLinux [
    inputs.t3code-nix.packages.${pkgs.stdenv.hostPlatform.system}.t3code
  ];
}
