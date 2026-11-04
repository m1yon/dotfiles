{
  config,
  pkgs,
  nixConfigDir,
  ...
}:

let
  webapps = builtins.fromJSON (builtins.readFile ../../../dotfiles/webapps.json);

  # Extract domain from a URL for favicon fetching
  domainOf =
    url:
    let
      # Remove protocol prefix
      noProto = builtins.replaceStrings [ "https://" "http://" ] [ "" "" ] url;
      # Take everything before the first /
      parts = builtins.split "/" noProto;
    in
    builtins.head parts;

  # Sanitize name for use as a filename (lowercase, no spaces)
  sanitizeName = name: builtins.replaceStrings [ " " ] [ "-" ] (pkgs.lib.toLower name);

  # An absolute path, so launching does not depend on the session PATH.
  launchCommand = app: ''${nixConfigDir}/scripts/bash/linux/launch-webapp "${app.url}"'';

  # Generate a desktop entry for a webapp
  mkDesktopEntry = app: {
    name = sanitizeName app.name;
    value = {
      name = app.name;
      exec = launchCommand app;
      icon = "${config.home.homeDirectory}/.local/share/applications/icons/${sanitizeName app.name}.png";
      type = "Application";
      categories = [
        "Network"
        "WebBrowser"
      ];
      settings = {
        # GNOME uses this to focus a running window instead of opening a second one.
        StartupWMClass = "chrome-${domainOf app.url}__-Default";
      };
    };
  };

  mkAutostart = app: {
    name = "autostart/${sanitizeName app.name}.desktop";
    value.text = ''
      [Desktop Entry]
      Type=Application
      Name=${app.name}
      Exec=${launchCommand app}
    '';
  };

  autostartApps = builtins.filter (app: app.autostart or false) webapps;

  # Favicon fetch script
  iconDir = "${config.home.homeDirectory}/.local/share/applications/icons";
  fetchCommands = builtins.concatStringsSep "\n" (
    map (
      app:
      let
        domain = domainOf app.url;
        filename = "${sanitizeName app.name}.png";
      in
      ''
        if [ ! -f "${iconDir}/${filename}" ]; then
          ${pkgs.curl}/bin/curl -sL "https://www.google.com/s2/favicons?domain=${domain}&sz=128" -o "${iconDir}/${filename}" || true
        fi
      ''
    ) webapps
  );
in
{
  xdg.desktopEntries = builtins.listToAttrs (map mkDesktopEntry webapps);

  xdg.configFile = builtins.listToAttrs (map mkAutostart autostartApps);

  home.activation.fetchWebappIcons = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "${iconDir}"
    ${fetchCommands}
  '';
}
