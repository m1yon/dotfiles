{ config, pkgs, ... }:
let
  linear-linux = pkgs.appimageTools.wrapType2 {
    pname = "linear-linux";
    version = "0.2.5";

    src = pkgs.fetchurl {
      url = "https://github.com/selimaj-dev/linear-linux/releases/download/v0.2.5/linear-linux-0.2.5-x86_64.AppImage";
      hash = "sha256:34199f5f2ae6b4171c38b2f3062c1b902c80f081b1b58f804088005717eb6a79";
    };

    extraInstallCommands =
      let
        appimageContents = pkgs.appimageTools.extractType2 {
          inherit (linear-linux) pname version src;
        };
      in
      ''
        install -m 444 -D ${appimageContents}/linear-linux.desktop $out/share/applications/linear-linux.desktop
        substituteInPlace $out/share/applications/linear-linux.desktop \
          --replace-fail 'Exec=AppRun' 'Exec=linear-linux'
        cp -r ${appimageContents}/usr/share/icons $out/share/icons
      '';
  };
in
{
  home.packages = [
    linear-linux
  ];

  sops.secrets = {
    linear_api_key.sopsFile = ../../secrets/linear.yaml;
  };

  sops.templates."linear-env" = {
    content = ''
      export LINEAR_API_KEY="${config.sops.placeholder.linear_api_key}"
    '';
  };

  programs.zsh.initContent = ''
    [ -f "${config.sops.templates."linear-env".path}" ] && source "${
      config.sops.templates."linear-env".path
    }"
  '';
}
