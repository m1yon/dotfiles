{
  coreutils,
  jq,
  username,
  writeShellApplication,
}:

writeShellApplication {
  name = "todoist-today";
  runtimeInputs = [
    coreutils
    jq
  ];
  text = ''
    PATH="$PATH:/etc/profiles/per-user/${username}/bin"
  ''
  + builtins.readFile ./todoist-today.sh;
}
