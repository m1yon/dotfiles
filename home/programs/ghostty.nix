{
  programs.ghostty = {
    enable = true;
    settings = {
      confirm-close-surface = false;
    };
  };

  xdg.configFile."xfce4/helpers.rc".text = ''
    TerminalEmulator=ghostty
  '';
}
