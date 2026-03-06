{ pkgs, ... }:

{
  programs.foot = {
    enable = true;
    settings = {
      main = {
        font = "monospace:size=11";
        include = "${pkgs.foot.themes}/share/foot/themes/tokyonight-night";
      };
    };
  };
}
