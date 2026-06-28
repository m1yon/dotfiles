{
  lib,
  nixConfigDir,
  pkgs,
  ...
}:

let
  scriptDirs = [
    "${nixConfigDir}/scripts/bun/bin/shared"
  ]
  ++ lib.optionals pkgs.stdenv.isDarwin [
    "${nixConfigDir}/scripts/bun/bin/darwin"
  ]
  ++ lib.optionals pkgs.stdenv.isLinux [
    "${nixConfigDir}/scripts/bun/bin/linux"
  ];
in
{
  home.sessionPath = scriptDirs;
}
