{ ... }:

{
  imports = [
    ./boot.nix
    ./networking.nix
    ./desktop.nix
    ./printing-scanning.nix
    ./audio.nix
    ./bluetooth.nix
    ./users.nix
    ./ssh.nix
    ./codex.nix
    ./development.nix
    ./docker.nix
    ./localsend.nix
    ./memory.nix
    ../system/agents.nix
  ];
}
