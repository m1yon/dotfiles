{
  lib,
  nixConfigDir,
  pkgs,
  ...
}:

let
  scriptDirs = [
    "${nixConfigDir}/scripts/bash/shared"
  ]
  ++ lib.optionals pkgs.stdenv.isDarwin [
    "${nixConfigDir}/scripts/bash/darwin"
  ]
  ++ lib.optionals pkgs.stdenv.isLinux [
    "${nixConfigDir}/scripts/bash/linux"
  ];
in
{
  home.sessionPath = scriptDirs;
}
