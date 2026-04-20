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
        "--use-angle=vulkan"
        "--enable-features=VaapiVideoDecoder,VaapiIgnoreDriverChecks,Vulkan,DefaultANGLEVulkan,VulkanFromANGLE,UseMultiPlaneFormatForHardwareVideo,VaapiVideoEncoder,CanvasOopRasterization"
      ];
    };
  };
}
