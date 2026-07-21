{
  config,
  lib,
  pkgs,
  ...
}:

let
  spaceApps = (builtins.fromJSON (builtins.readFile ../../dotfiles/spaces/apps.json)).apps;
  startupApps = builtins.filter (app: app.startup or false) spaceApps;
  requiredSpaceCount = lib.foldl' lib.max 1 (map (app: app.space) spaceApps);

  startupBindingChecks = lib.concatMapStringsSep "\n" (
    app:
    let
      spaceIndex = app.space - 1;
      bundleId = lib.escapeShellArg app.bundleId;
    in
    ''
      expected_uuid="$(printf '%s' "$spaces_json" | ${pkgs.jq}/bin/jq -r '[.SpacesDisplayConfiguration["Management Data"].Monitors[] | select(.Spaces != null) | .Spaces[] | select(.type == 0)] | .[${toString spaceIndex}].uuid // empty')"
      bound_uuid="$(printf '%s' "$spaces_json" | ${pkgs.jq}/bin/jq -r --arg bundle ${bundleId} '.["app-bindings"][$bundle] // empty')"
      [[ -n "$expected_uuid" && "$bound_uuid" == "$expected_uuid" ]] || exit 0
    ''
  ) startupApps;

  startupAppsScript = pkgs.writeShellScript "start-native-space-apps" ''
    spaces_preferences=${lib.escapeShellArg "${config.home.homeDirectory}/Library/Preferences/com.apple.spaces.plist"}
    [[ -f "$spaces_preferences" ]] || exit 0

    spaces_json="$(/usr/bin/plutil -convert json -o - "$spaces_preferences" 2>/dev/null || true)"
    ${startupBindingChecks}

    /bin/sleep 2
    ${lib.concatMapStringsSep "\n" (
      app: "/usr/bin/open -g -j -b ${lib.escapeShellArg app.bundleId}"
    ) startupApps}
  '';

  spaceBindingCommands = lib.concatMapStringsSep "\n" (
    app:
    let
      spaceIndex = app.space - 1;
      bundleId = lib.escapeShellArg app.bundleId;
    in
    ''
      space_uuid="$(printf '%s' "$spaces_json" | ${pkgs.jq}/bin/jq -r '[.SpacesDisplayConfiguration["Management Data"].Monitors[] | select(.Spaces != null) | .Spaces[] | select(.type == 0)] | .[${toString spaceIndex}].uuid // empty')"
      current_uuid="$(printf '%s' "$spaces_json" | ${pkgs.jq}/bin/jq -r --arg bundle ${bundleId} '.["app-bindings"][$bundle] // empty')"

      if [[ -z "$space_uuid" ]]; then
        warnEcho "Native Space ${toString app.space} has no UUID; skipping ${app.name}."
      elif [[ "$current_uuid" != "$space_uuid" ]]; then
        run /usr/bin/defaults write com.apple.spaces app-bindings -dict-add ${bundleId} "$space_uuid"
        bindings_changed=1
      fi
    ''
  ) spaceApps;
in
{
  assertions = [
    {
      assertion = lib.all (
        app:
        builtins.isString app.name
        && builtins.isString app.bundleId
        && builtins.isInt app.space
        && app.space > 0
        && app.space <= 10
      ) spaceApps;
      message = "Every dotfiles/spaces/apps.json entry must have a name, bundleId, and Space number from 1 through 10.";
    }
  ];

  home.file.".hammerspoon/init.lua".source = ../../dotfiles/hammerspoon/init.lua;

  launchd.agents.hammerspoon = {
    enable = true;
    config = {
      ProgramArguments = [
        "/usr/bin/open"
        "-g"
        "-j"
        "-a"
        "Hammerspoon"
      ];
      ProcessType = "Interactive";
      RunAtLoad = true;
    };
  };

  launchd.agents.native-space-startup-apps = {
    enable = true;
    config = {
      ProgramArguments = [ "${startupAppsScript}" ];
      ProcessType = "Background";
      RunAtLoad = true;
    };
  };

  # Native Space app bindings point at machine-local Space UUIDs. Resolve the
  # configured Space numbers at activation time while keeping the desired map
  # declarative in dotfiles/spaces/apps.json.
  home.activation.bindNativeSpaceApps = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    spaces_preferences=${lib.escapeShellArg "${config.home.homeDirectory}/Library/Preferences/com.apple.spaces.plist"}

    if [[ ! -f "$spaces_preferences" ]]; then
      warnEcho "macOS Spaces preferences do not exist yet; skipping app bindings."
    else
      spaces_json="$(/usr/bin/plutil -convert json -o - "$spaces_preferences" 2>/dev/null || true)"
      space_count="$(printf '%s' "$spaces_json" | ${pkgs.jq}/bin/jq -r '[.SpacesDisplayConfiguration["Management Data"].Monitors[] | select(.Spaces != null) | .Spaces[] | select(.type == 0)] | length' 2>/dev/null || printf '0')"

      if (( space_count < ${toString requiredSpaceCount} )); then
        warnEcho "Native Spaces: found $space_count, need ${toString requiredSpaceCount}. Create the missing Spaces, then rebuild again to bind apps."
      else
        bindings_changed=0
        ${spaceBindingCommands}

        if (( bindings_changed )); then
          run /usr/bin/killall Dock || true
        fi
      fi
    fi
  '';
}
