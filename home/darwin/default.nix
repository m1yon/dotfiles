{ lib, pkgs, ... }:

let
  ghosttySettings = {
    theme = "TokyoNight Night";
    confirm-close-surface = false;
    clipboard-read = "allow";
    clipboard-write = "allow";
    background-opacity = 1;
    background-blur = false;
    unfocused-split-opacity = 1;
    alpha-blending = "linear-corrected";
    bold-color = "bright";
    faint-opacity = 1;
    auto-update = "off";
  };

  formatGhosttyValue =
    value: if builtins.isBool value then lib.boolToString value else toString value;

  ghosttyConfig =
    lib.concatStringsSep "\n" (
      lib.mapAttrsToList (name: value: "${name} = ${formatGhosttyValue value}") ghosttySettings
    )
    + "\n";
in
{
  imports = [
    ./codex.nix
    ./packages.nix
    ./shell.nix
  ];

  home.file."Library/Application Support/com.mitchellh.ghostty/config.ghostty" = {
    force = true;
    text = ghosttyConfig;
  };

  home.activation.defaultBrowser = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if /usr/bin/open -Ra "Google Chrome" >/dev/null 2>&1; then
      ${pkgs.duti}/bin/duti -s com.google.Chrome http
    else
      echo "Google Chrome is not installed; skipping default browser setup." >&2
    fi
  '';
}
