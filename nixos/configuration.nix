{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./boot.nix
    ./networking.nix
    ./desktop.nix
    ./audio.nix
    ./users.nix
    ./ssh.nix
  ];
}
