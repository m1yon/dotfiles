{
  coreutils,
  jq,
  writeShellApplication,
}:

writeShellApplication {
  name = "todoist-stale";
  runtimeInputs = [
    coreutils
    jq
  ];
  text = builtins.readFile ./todoist-stale.sh;
}
