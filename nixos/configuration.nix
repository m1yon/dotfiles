{ ... }:

{
  imports = [
    ./boot.nix
    ./networking.nix
    ./desktop.nix
    ./audio.nix
    ./bluetooth.nix
    ./users.nix
    ./ssh.nix
    ./codex.nix
    ./development.nix
    ./docker.nix
    ./memory.nix
    ../system/agents.nix
  ];
}
