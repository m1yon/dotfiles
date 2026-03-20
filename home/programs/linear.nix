{ pkgs, ... }:
let
  linear-linux = pkgs.stdenv.mkDerivation rec {
    pname = "linear-linux";
    version = "0.2.3";

    src = pkgs.fetchurl {
      url = "https://github.com/zacharyftw/linear-linux/releases/download/v${version}/Linear_${version}_amd64.deb";
      hash = "sha256-Hp3fT1DAvemT3jlQEJqDF0iXwbQm0+WutM///O5j4YI=";
    };

    nativeBuildInputs = with pkgs; [
      dpkg
      autoPatchelfHook
      wrapGAppsHook3
    ];

    buildInputs = with pkgs; [
      gtk3
      webkitgtk_4_1
      libsoup_3
      glib
      glib-networking
      gdk-pixbuf
      cairo
    ];

    unpackPhase = ''
      dpkg-deb -x $src .
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin $out/share
      cp usr/bin/linear-linux $out/bin/
      cp -r usr/share/applications $out/share/
      cp -r usr/share/icons $out/share/

      substituteInPlace $out/share/applications/Linear.desktop \
        --replace-fail 'Exec=linear-linux' "Exec=$out/bin/linear-linux"

      runHook postInstall
    '';
  };
in
{
  home.packages = [
    linear-linux
  ];
}
