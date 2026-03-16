{ pkgs, ... }:

{
  environment.systemPackages = [ pkgs.bluetui ];

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        # Shows battery charge of connected devices on supported
        # Bluetooth adapters. Defaults to 'false'.
        Experimental = true;
        # When enabled other devices can connect faster to us, however
        # the tradeoff is increased power consumption. Defaults to
        # 'false'.
        FastConnectable = true;
        # Default controller class: computer (desktop)
        Class = "0x000100";
      };
      Policy = {
        # Enable all controllers when they are found. This includes
        # adapters present on start as well as adapters that are plugged
        # in later on. Defaults to 'true'.
        AutoEnable = true;
      };
    };
  };

  # Unblock soft-blocked adapter on boot (Ideapad firmware blocks it by default)
  boot.kernelModules = [ "btusb" ];
  systemd.services.bluetooth-setup = {
    description = "Unblock and power on Bluetooth adapter";
    after = [ "bluetooth.service" ];
    requires = [ "bluetooth.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      ${pkgs.util-linux}/bin/rfkill unblock bluetooth
      sleep 1
      ${pkgs.bluez}/bin/bluetoothctl power on
    '';
  };
}
