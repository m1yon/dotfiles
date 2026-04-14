{ pkgs, ... }:
let
  claude-devtools = pkgs.appimageTools.wrapType2 {
    pname = "claude-devtools";
    version = "0.4.10";

    src = pkgs.fetchurl {
      url = "https://github.com/matt1398/claude-devtools/releases/download/v0.4.10/claude-devtools-0.4.10.AppImage";
      hash = "sha256-WRZC+NdLQsalt17GCLGLC9KdJOkqPdIOpFG33soUJ58=";
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
