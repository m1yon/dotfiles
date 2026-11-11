{
  jq,
  shfmt,
  writeShellApplication,
}:

writeShellApplication {
  name = "agent-guard";
  runtimeInputs = [
    jq
    shfmt
  ];
  text = builtins.readFile ./agent-guard.sh;
}
