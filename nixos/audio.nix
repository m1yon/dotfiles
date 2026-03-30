{ pkgs, ... }:

{
  environment.systemPackages = [
    pkgs.wiremix
    pkgs.pulseaudio
  ];
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;

  # Ensure dynamically-linked apps (e.g. miniaudio/malgo) can find ALSA + PipeWire plugin.
  environment.sessionVariables = {
    LD_LIBRARY_PATH = "${pkgs.alsa-lib}/lib";
    ALSA_PLUGIN_DIR = "${pkgs.pipewire}/lib/alsa-lib";
  };

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;

    wireplumber.extraConfig.bluetoothEnhancements = {
      "monitor.bluez.properties" = {
        # Enable all HFP/HSP roles for hands-free microphone support.
        "bluez5.roles" = [
          "hsp_hs"
          "hsp_ag"
          "hfp_hf"
          "hfp_ag"
          "a2dp_sink"
          "a2dp_source"
        ];
        # Enable high-quality A2DP codecs (AAC, LDAC, aptX, aptX HD).
        "bluez5.codecs" = [
          "aac"
          "ldac"
          "aptx"
          "aptx_hd"
          "sbc"
          "sbc_xq"
        ];
        # Auto-switch to HSP/HFP when mic is needed, back to A2DP when done.
        "bluez5.autoswitch-profile" = true;
        # Enable mSBC codec for wideband speech in HFP.
        "bluez5.enable-msbc" = true;
        # Enable SBC-XQ for higher quality A2DP.
        "bluez5.enable-sbc-xq" = true;
        # Enable hardware volume control on supported devices.
        "bluez5.enable-hw-volume" = true;
      };
    };

    # Default to A2DP sink profile for Bluetooth audio devices.
    wireplumber.extraConfig.bluetoothProfile = {
      "monitor.bluez.rules" = [
        {
          matches = [
            { "device.name" = "~bluez_card.*"; }
          ];
          actions = {
            update-props = {
              "bluez5.auto-connect" = [ "a2dp_sink" ];
              "bluez5.profile" = "a2dp-sink";
            };
          };
        }
      ];
    };
  };
}
