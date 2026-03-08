{ pkgs, inputs, ... }:

{
  stylix = {
    enable = true;
    base16Scheme = "${inputs.tt-schemes}/base16/tokyo-night-dark.yaml";
    polarity = "dark";

    fonts = {
      monospace = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetBrainsMono Nerd Font";
      };
      sizes.terminal = 11;
    };

    autoEnable = false;
    targets.foot.enable = true;
    targets.gtk.enable = true;
  };
}
