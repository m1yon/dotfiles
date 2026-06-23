{
  lib,
  username,
  ...
}:

let
  loginItemsToRemove = [
    "Microsoft Teams"
    "Teams"
  ];

  removeLoginItem = name: ''
    launchctl asuser "$uid" sudo --user="$user" -- osascript -e ${lib.escapeShellArg ''
      tell application "System Events"
        if exists login item "${name}" then delete login item "${name}"
      end tell
    ''}
  '';
in
{
  system.activationScripts.removeTeamsLoginItems.text = lib.mkAfter ''
    echo "removing Teams from macOS Login Items..." >&2
    user=${lib.escapeShellArg username}
    uid="$(id -u -- "$user")"

    ${lib.concatMapStringsSep "\n" removeLoginItem loginItemsToRemove}
  '';
}
