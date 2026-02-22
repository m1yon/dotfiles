{ config, pkgs, ... }:

{
  # TODO please change the username & home directory to your own
  home.username = "michael";
  home.homeDirectory = "/home/michael";

  # Import files from the current configuration directory into the Nix store,
  # and create symbolic links pointing to those store files in the Home directory.

  # home.file.".config/i3/wallpaper.jpg".source = ./wallpaper.jpg;

  # Import the scripts directory into the Nix store,
  # and recursively generate symbolic links in the Home directory pointing to the files in the store.
  # home.file.".config/i3/scripts" = {
  #   source = ./scripts;
  #   recursive = true;   # link recursively
  #   executable = true;  # make all files executable
  # };

  # encode the file content in nix configuration file directly
  # home.file.".xxx".text = ''
  #     xxx
  # '';

  imports = [
    ./programs
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    MANPAGER = "nvim +Man!";
    AWS_SDK_LOAD_CONFIG = 1;
  };

  home.sessionPath = {
  }

  # basic configuration of git, please change to your own
  programs.git = {
    enable = true;
    userName = "Michael Lyon";
    userEmail = "mlyon360@gmail.com";
  };


  # This value determines the home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update home Manager without changing this value. See
  # the home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "25.11";
}
