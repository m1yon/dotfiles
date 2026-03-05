{ pkgs, ... }:

{
  environment.systemPackages = [ pkgs.wiremix ];
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;

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
        ];
        # Enable mSBC codec for wideband speech in HFP.
        "bluez5.enable-msbc" = true;
        # Enable SBC-XQ for higher quality A2DP.
        "bluez5.enable-sbc-xq" = true;
        # Enable hardware volume control on supported devices.
        "bluez5.enable-hw-volume" = true;
      };
    };
  };
}
