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

  # JSON string quoting also produces Lua string literals for these values.
  luaString = builtins.toJSON;
  launchCommand = app: ''launch-or-focus-webapp "${app.name}" "${app.url}"'';

  # Web-app binds use Lua's "SUPER + SHIFT + K" notation.
  mkBind =
    app:
    if app ? bind then
      "hl.bind(${luaString app.bind}, hl.dsp.exec_cmd(${luaString (launchCommand app)}))"
    else
      null;

  # Derive Chrome --app= class regex from URL domain
  chromeClassOf = url: "chrome-" + domainOf url + ".*";

  # Generate hyprland window rule block for an app
  mkWindowRules =
    app:
    let
      hasRules = app ? workspace || (app ? group && app.group);
      workspaceLine = if app ? workspace then "  workspace = ${luaString app.workspace},\n" else "";
      groupLine = if app ? group && app.group then "  group = \"set\",\n" else "";
      suppressLine = if app ? autostart && app.autostart then "  no_initial_focus = true,\n" else "";
      block = "hl.window_rule({\n  name = ${luaString "webapp-${sanitizeName app.name}"},\n${workspaceLine}${groupLine}${suppressLine}  match = { class = ${luaString (chromeClassOf app.url)} },\n})";
    in
    if hasRules then [ block ] else [ ];

  # Launch once per session, without switching to the app's workspace.
  mkAutostart =
    app:
    if app ? autostart && app.autostart then
      let
        rules = if app ? workspace then ", { workspace = ${luaString "${app.workspace} silent"} }" else "";
      in
      "  hl.exec_cmd(${luaString (launchCommand app)}${rules})"
    else
      null;

  binds = builtins.filter (x: x != null) (map mkBind webapps);
  windowRules = pkgs.lib.concatMap mkWindowRules webapps;
  autostarts = builtins.filter (x: x != null) (map mkAutostart webapps);
  hyprConf = builtins.concatStringsSep "\n" (
    binds ++ windowRules ++ [ "hl.on(\"hyprland.start\", function()" ] ++ autostarts ++ [ "end)" ]
  );

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

  home.file.".config/hypr/hyprland.lua".text =
    builtins.readFile ../../../dotfiles/hyprland/hyprland.lua + "\n" + hyprConf + "\n";

  home.activation.fetchWebappIcons = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "${iconDir}"
    ${fetchCommands}
  '';
}
