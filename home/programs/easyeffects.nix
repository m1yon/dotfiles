{ pkgs, ... }:

{
  services.easyeffects.enable = true;

  # Make the DeepFilterNet LADSPA plugin discoverable to easyeffects.
  home.sessionVariables.LADSPA_PATH = "${pkgs.deepfilternet}/lib/ladspa";
  systemd.user.services.easyeffects.Service.Environment = [
    "LADSPA_PATH=${pkgs.deepfilternet}/lib/ladspa"
  ];
}
