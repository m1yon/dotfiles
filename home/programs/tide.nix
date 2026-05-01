{ pkgs, inputs, ... }:
{
  home.packages = [
    inputs.tide.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
