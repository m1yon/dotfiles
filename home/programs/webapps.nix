{
  config,
  pkgs,
  nixConfigDir,
  ...
}:

let
  webapps = builtins.fromJSON (builtins.readFile ../../dotfiles/webapps.json);

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

  # Generate a desktop entry for a webapp
  mkDesktopEntry = app: {
    name = sanitizeName app.name;
    value = {
      name = app.name;
      exec = "launch-or-focus-webapp \"${app.name}\" \"${app.url}\"";
      icon = "${config.home.homeDirectory}/.local/share/applications/icons/${sanitizeName app.name}.png";
      type = "Application";
      categories = [
        "Network"
        "WebBrowser"
      ];
    };
  };

  # Generate hyprland bind line for a webapp
  mkBind =
    app:
    if app ? bind then
      "bind = ${app.bind}, exec, launch-or-focus-webapp \"${app.name}\" \"${app.url}\""
    else
      null;

  # Generate hyprland windowrulev2 line for workspace assignment
  mkWindowRule =
    app:
    if app ? workspace then "windowrulev2 = workspace ${app.workspace}, title:${app.name}" else null;

  binds = builtins.filter (x: x != null) (map mkBind webapps);
  windowRules = builtins.filter (x: x != null) (map mkWindowRule webapps);
  hyprConf = builtins.concatStringsSep "\n" (binds ++ windowRules);

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

  home.file.".config/hypr/webapps.conf".text = hyprConf + "\n";

  home.activation.fetchWebappIcons = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "${iconDir}"
    ${fetchCommands}
  '';
}
