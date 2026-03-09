{
  pkgs,
  username,
  ...
}:

{
  boot.kernelModules = [ "vhost_vsock" ];

  users.users.${username}.extraGroups = [ "kvm" ];

  environment.systemPackages = with pkgs; [
    qemu
    socat
    virtiofsd
  ];

  services.udev.extraRules = ''
    KERNEL=="vhost-vsock", GROUP="kvm", MODE="0660"
  '';
}
