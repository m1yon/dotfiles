{ pkgs, ... }:
let
  vibetyper = pkgs.appimageTools.wrapType2 {
    pname = "vibetyper";
    version = "1.1.8";

    src = pkgs.fetchurl {
      url = "https://cdn.vibetyper.com/releases/linux/VibeTyper.AppImage";
      hash = "sha256-wMx2tK4/aiKQrgICgNjRn2l1rHa5+bSvzB1e6WtB7sg=";
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
