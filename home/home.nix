{ username, ... }:

{
  imports = [
    ./users/michael.nix
    ./linux
  ];

  _module.args.homeDirectory = "/home/${username}";
}
