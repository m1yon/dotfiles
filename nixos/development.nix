{ ... }:

{
  # nix-ld provides a compatibility layer for dynamically linked binaries.
  programs.nix-ld.enable = true;

  # T3 Code's updater launches the new AppImage directly when it restarts.
  programs.appimage = {
    enable = true;
    binfmt = true;
  };
}
