{
  gnused,
  jq,
  shfmt,
  writeShellApplication,
}:

writeShellApplication {
  name = "agent-guard";
  runtimeInputs = [
    gnused
    jq
    shfmt
  ];
  text = builtins.readFile ./agent-guard.sh;
}
