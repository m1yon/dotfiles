{
  programs.ghostty = {
    enable = true;
    settings = {
      theme = "TokyoNight Night"; # TODO: move to stylix
      confirm-close-surface = false;
    };
  };

  xdg.configFile."xfce4/helpers.rc".text = ''
    TerminalEmulator=ghostty
  '';
}
