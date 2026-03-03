{
  nixConfigDir,
  ...
}:

let
  wallpaper = "${nixConfigDir}/wallpapers/sky-grass.jpg";
in
{
  services.hyprpaper = {
    enable = true;
    settings = {
      preload = [ wallpaper ];
      wallpaper = [ ",${wallpaper}" ];
    };
  };
}
