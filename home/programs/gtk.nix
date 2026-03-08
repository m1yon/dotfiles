{ pkgs, ... }:

{
  gtk = {
    enable = true;

    iconTheme = {
      name = "rose-pine";
      package = pkgs.rose-pine-icon-theme;
    };
  };

  # Prefer dark color scheme via dconf (used by GTK4/libadwaita apps)
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };
}
