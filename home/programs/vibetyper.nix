{ pkgs, ... }:
let
  vibetyper = pkgs.appimageTools.wrapType2 {
    pname = "vibetyper";
    version = "1.3.2";

    src = pkgs.fetchurl {
      url = "https://cdn.vibetyper.com/releases/linux/VibeTyper.AppImage";
      hash = "sha256-iL43oBamDM+bd7Be+FrHVuSEXMd8a/skGzanhX+avF8=";
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
