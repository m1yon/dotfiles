{
  programs.ghostty = {
    enable = true;
    settings = {
      theme = "TokyoNight Night"; # TODO: move to stylix
      confirm-close-surface = false;
      clipboard-read = "allow";
      clipboard-write = "allow";
      background-opacity = 1;
      background-blur = false;
      unfocused-split-opacity = 1;
      alpha-blending = "linear-corrected";
      bold-color = "bright";
      faint-opacity = 1;
      gtk-single-instance = true;
    };
  };

  xdg.configFile."xfce4/helpers.rc".text = ''
    TerminalEmulator=ghostty
  '';
}
