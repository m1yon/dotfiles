{ username, ... }:

{
  # Start user services at boot and keep them alive after the last SSH logout.
  users.users.${username}.linger = true;

  # Use nixbook as a remote worker with the lid closed while plugged in.
  # Closing the lid on battery still suspends it.
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "ignore";
    HandleLidSwitchDocked = "ignore";
    IdleAction = "ignore";
  };
}
