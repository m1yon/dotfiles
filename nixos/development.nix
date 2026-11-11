{ ... }:

{
  # nix-ld provides a compatibility layer for dynamically linked binaries, such
  # as the t3 runtime that home/linux/programs/t3code.nix downloads.
  programs.nix-ld.enable = true;
}
