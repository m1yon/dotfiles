{ pkgs, ... }:

{
  home.packages = [
    pkgs.bat
    pkgs.coreutils
    pkgs.dnsutils
    pkgs.fd
    pkgs.file
    pkgs.gnumake
    pkgs.just
    pkgs.lsof
    pkgs.openssl
    pkgs.pkg-config
    pkgs.ripgrep
    pkgs.rsync
    pkgs.sqlite
    pkgs.tree
    pkgs.uv
    pkgs.wget
    pkgs.yq-go
    pkgs.zip
  ];

  home.sessionPath = [
    "$HOME/.local/bin"
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    MANPAGER = "nvim +Man!";
    AWS_SDK_LOAD_CONFIG = 1;
  };
}
