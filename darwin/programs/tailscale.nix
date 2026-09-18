{ username, ... }:

{
  homebrew.casks = [ "tailscale-app" ];

  # A separate alias avoids the LAN address in the SOPS-managed SSH config.
  programs.ssh.extraConfig = ''
    Host nixbook-tailnet
      HostName nixbook
      User ${username}

    Host *
  '';
}
