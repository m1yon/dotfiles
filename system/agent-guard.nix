{
  gnused,
  jq,
  writeShellApplication,
}:

writeShellApplication {
  name = "agent-guard";
  runtimeInputs = [
    gnused
    jq
  ];
  text = builtins.readFile ./agent-guard.sh;
}
