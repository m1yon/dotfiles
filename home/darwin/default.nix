{ lib, pkgs, ... }:

{
  imports = [
    ./packages.nix
    ./shell.nix
  ];

  home.activation.defaultBrowser = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if /usr/bin/open -Ra "Google Chrome" >/dev/null 2>&1; then
      ${pkgs.duti}/bin/duti -s com.google.Chrome http
      ${pkgs.duti}/bin/duti -s com.google.Chrome https
      ${pkgs.duti}/bin/duti -s com.google.Chrome public.html all
      ${pkgs.duti}/bin/duti -s com.google.Chrome public.xhtml all
    else
      echo "Google Chrome is not installed; skipping default browser setup." >&2
    fi
  '';
}
