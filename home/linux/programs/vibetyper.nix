{
  config,
  pkgs,
  ...
}:
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

  home.activation.disableVibeTyperAutoUpdates = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    config_file="${config.xdg.configHome}/vibe-typer/config.json"
    if [ -f "$config_file" ]; then
      tmp_file="$(${pkgs.coreutils}/bin/mktemp)"
      if ${pkgs.jq}/bin/jq '.user.automaticUpdatesEnabled = false' "$config_file" > "$tmp_file"; then
        ${pkgs.coreutils}/bin/mv "$tmp_file" "$config_file"
      else
        ${pkgs.coreutils}/bin/rm -f "$tmp_file"
      fi
    else
      ${pkgs.coreutils}/bin/mkdir -p "$(${pkgs.coreutils}/bin/dirname "$config_file")"
      ${pkgs.coreutils}/bin/printf '%s\n' '{"version":4,"user":{"automaticUpdatesEnabled":false}}' > "$config_file"
    fi
  '';
}
