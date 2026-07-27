{ lib, pkgs, ... }:

let
  ghosttySettings = {
    theme = "TokyoNight Night";
    font-size = 15;
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

  ghosttyKeybinds = [
    # Send Ctrl-S so Cmd-S triggers Neovim's existing save mapping.
    "super+s=text:\\x13"
  ];

  formatGhosttyValue =
    value: if builtins.isBool value then lib.boolToString value else toString value;

  ghosttyConfig =
    lib.concatStringsSep "\n" (
      lib.mapAttrsToList (name: value: "${name} = ${formatGhosttyValue value}") ghosttySettings
      ++ map (keybind: "keybind = ${keybind}") ghosttyKeybinds
    )
    + "\n";

  codexDefaults = {
    SUEnableAutomaticChecks = false;
    SUAutomaticallyUpdate = false;
  };
in
{
  imports = [
    ./codex.nix
    ./flashspace.nix
    ./jankyborders.nix
    ./packages.nix
    ./shell.nix
  ];

  services.gpg-agent = {
    enable = true;
    defaultCacheTtl = 3600;
    maxCacheTtl = 7200;
    pinentry.package = pkgs.pinentry_mac;
    enableSshSupport = false;
    enableZshIntegration = true;
  };

  home.file."Library/Application Support/com.mitchellh.ghostty/config.ghostty" = {
    force = true;
    text = ghosttyConfig;
  };

  targets.darwin.defaults."com.openai.codex" = codexDefaults;

  home.activation.defaultBrowser = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if /usr/bin/open -Ra "Google Chrome" >/dev/null 2>&1; then
      ${pkgs.duti}/bin/duti -s com.google.Chrome http
    else
      echo "Google Chrome is not installed; skipping default browser setup." >&2
    fi
  '';
}
