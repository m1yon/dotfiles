{ pkgs, ... }:
{
  home.packages = with pkgs; [
    claude-desktop
  ];

  home.sessionVariables = {
    CLAUDE_USE_WAYLAND = "1";
  };
}
