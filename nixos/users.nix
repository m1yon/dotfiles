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
      "networkmanager"
      "wheel"
    ];
    packages = with pkgs; [ ];
    shell = pkgs.zsh;
  };
}
