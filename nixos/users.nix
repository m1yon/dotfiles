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
    packages = with pkgs; [ ];
    shell = pkgs.zsh;
  };
}
