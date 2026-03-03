{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./boot.nix
    ./networking.nix
    ./desktop.nix
    ./audio.nix
    ./bluetooth.nix
    ./users.nix
    ./ssh.nix
    ./development.nix
  ];
}
