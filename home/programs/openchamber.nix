{ pkgs, ... }:

let
  openchamber = pkgs.writeShellScriptBin "openchamber" ''
    export PATH=${
      pkgs.lib.makeBinPath [
        pkgs.bun
        pkgs.nodejs
        pkgs.stdenv.cc
        pkgs.gnumake
        pkgs.python3
        pkgs.pkg-config
      ]
    }''${PATH:+:$PATH}
    export npm_config_libc=glibc
    exec ${pkgs.bun}/bin/bunx --bun @openchamber/web@1.10.4 "$@"
  '';
in
{
  home.packages = [ openchamber ];
}
