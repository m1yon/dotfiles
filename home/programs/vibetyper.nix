{ pkgs, ... }:
let
  vibetyper = pkgs.appimageTools.wrapType2 {
    pname = "vibetyper";
    version = "1.3.1";

    src = pkgs.fetchurl {
      url = "https://cdn.vibetyper.com/releases/linux/VibeTyper.AppImage";
      hash = "sha256-nV8bTDp17gIl6ngpdGudA04/rtGVzLUsEVQyiTfsies=";
    };

    extraInstallCommands =
      let
        appimageContents = pkgs.appimageTools.extractType2 {
          inherit (vibetyper) pname version src;
        };
      in
      ''
        install -m 444 -D ${appimageContents}/vibe-typer.desktop $out/share/applications/vibe-typer.desktop
        substituteInPlace $out/share/applications/vibe-typer.desktop \
          --replace-fail 'Exec=AppRun' 'Exec=env PASSWORD_STORE_BACKEND=gnome-libsecret vibetyper --password-store=gnome-libsecret'
        cp -r ${appimageContents}/usr/share/icons $out/share/icons
      '';
  };
in
{
  home.packages = [
    vibetyper
    pkgs.wl-clipboard
  ];
}
