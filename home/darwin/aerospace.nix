{ lib, pkgs, ... }:

let
  aerospaceBaseConfig = builtins.readFile ../../dotfiles/aerospace/aerospace.toml;
  aerospaceApps = (builtins.fromJSON (builtins.readFile ../../dotfiles/aerospace/apps.json)).apps;

  routeCommands = app: [ "move-node-to-workspace ${app.workspace}" ] ++ (app.extraCommands or [ ]);

  runValue =
    app:
    let
      commands = routeCommands app;
    in
    if builtins.length commands == 1 then
      builtins.toJSON (builtins.head commands)
    else
      builtins.toJSON commands;

  appRule =
    app:
    lib.concatStringsSep "\n" [
      "# ${app.name}"
      "[[on-window-detected]]"
      "if.app-id = ${builtins.toJSON app.bundleId}"
      "run = ${runValue app}"
    ];

  generatedAppRules = lib.concatMapStringsSep "\n\n" appRule aerospaceApps;
  generatedHeader = lib.concatStringsSep "\n" [
    "# Generated app rules from dotfiles/aerospace/apps.json."
    "# Edit apps.json, then rebuild Home Manager/nix-darwin."
  ];

  finalAerospaceConfig =
    lib.concatStringsSep "\n\n" [
      (lib.removeSuffix "\n" aerospaceBaseConfig)
      generatedHeader
      generatedAppRules
    ]
    + "\n";
in
{
  home.packages = [
    pkgs.aerospace
  ];

  home.file.".aerospace.toml" = {
    text = finalAerospaceConfig;
    force = true;
  };
}
