{
  pkgs,
  config,
  username,
  ...
}:
{
  programs = {
    google-chrome = {
      enable = true;
      commandLineArgs = [
        "--ignore-gpu-blocklist"
        "--enable-gpu-rasterization"
        "--enable-zero-copy"
        "--enable-features=VaapiVideoDecoder,VaapiVideoEncoder,CanvasOopRasterization"
      ];
    };
  };
}
