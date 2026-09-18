{
  pkgs,
  username,
  ...
}:

{
  programs.zsh.enable = true;

  users.users.${username} = {
    isNormalUser = true;
    description = "Michael";
    extraGroups = [
      "wheel"
      "video"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPhVltcj+xAszoSlW5SdQueMX6/KwWPzJES/YoJPY6kb michael@macbook"
    ];
    packages = with pkgs; [ ];
    shell = pkgs.zsh;
  };
}
