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

  # Derive Chrome --app= class regex from URL domain
  chromeClassOf = url: "chrome-" + domainOf url + ".*";

  # Generate hyprland window rule block for an app
  mkWindowRules =
    app:
    let
      hasRules = app ? workspace || (app ? group && app.group);
      workspaceLine = if app ? workspace then "  workspace = ${app.workspace}\n" else "";
      groupLine = if app ? group && app.group then "  group = set\n" else "";
      suppressLine = if app ? autostart && app.autostart then "  no_initial_focus = true\n" else "";
      block = "windowrule {\n  name = webapp-${sanitizeName app.name}\n${workspaceLine}${groupLine}${suppressLine}  match:class = ${chromeClassOf app.url}\n}";
    in
    if hasRules then [ block ] else [ ];

  # Generate exec-once for autostart apps (silent when workspace is set)
  mkAutostart =
    app:
    if app ? autostart && app.autostart then
      let
        prefix = if app ? workspace then "[workspace ${app.workspace} silent] " else "";
      in
      "exec-once = ${prefix}launch-or-focus-webapp \"${app.name}\" \"${app.url}\""
    else
      null;

  binds = builtins.filter (x: x != null) (map mkBind webapps);
  windowRules = pkgs.lib.concatMap mkWindowRules webapps;
  autostarts = builtins.filter (x: x != null) (map mkAutostart webapps);
  hyprConf = builtins.concatStringsSep "\n" (binds ++ windowRules ++ autostarts);

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

  home.file.".config/hypr/hyprland.conf".text =
    builtins.readFile ../../dotfiles/hyprland/hyprland.conf + "\n" + hyprConf + "\n";

  home.activation.fetchWebappIcons = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "${iconDir}"
    ${fetchCommands}
  '';
}
