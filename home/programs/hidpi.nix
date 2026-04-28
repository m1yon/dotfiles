{
  # Companion to Hyprland's xwayland.force_zero_scaling. With XWayland not
  # scaling its surfaces, X/Qt apps need Xft.dpi to know how big to draw
  # (96 * 1.5 = 144 for the BenQ RD280UG at 2880x1920 with scale 1.5).
  xresources.properties = {
    "Xft.dpi" = 144;
  };
}
