{
  programs.ghostty = {
    enable = true;
    settings = {
      theme = "TokyoNight Night"; # TODO: move to stylix
      confirm-close-surface = false;
      clipboard-read = "allow";
      clipboard-write = "allow";
      gtk-single-instance = true;
    };
  };

  xdg.configFile."xfce4/helpers.rc".text = ''
    TerminalEmulator=ghostty
  '';
}
