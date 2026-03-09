{ pkgs, ... }:
let
  claude-devtools = pkgs.appimageTools.wrapType2 {
    pname = "claude-devtools";
    version = "0.4.8";

    src = pkgs.fetchurl {
      url = "https://github.com/matt1398/claude-devtools/releases/download/v0.4.8/claude-devtools-0.4.8.AppImage";
      hash = "sha256-dY4r8aITO9UhhEzuVA84FdhHllDOo+YKwc1EdzdYD1E=";
    };

    extraInstallCommands =
      let
        appimageContents = pkgs.appimageTools.extractType2 {
          inherit (claude-devtools) pname version src;
        };
      in
      ''
        install -m 444 -D ${appimageContents}/claude-devtools.desktop $out/share/applications/claude-devtools.desktop
        substituteInPlace $out/share/applications/claude-devtools.desktop \
          --replace-fail 'Exec=AppRun' 'Exec=claude-devtools'
        cp -r ${appimageContents}/usr/share/icons $out/share/icons
      '';
  };
in
{
  home.packages = [ claude-devtools ];
}
