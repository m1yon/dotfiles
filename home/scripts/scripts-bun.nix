{
  nixConfigDir,
  ...
}:

{
  home.sessionPath = [
    "${nixConfigDir}/scripts-bun/bin"
  ];
}
