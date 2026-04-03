{ config, ... }:
{
  sops.secrets = {
    linear_api_key.sopsFile = ../../secrets/linear.yaml;
  };

  sops.templates."linear-env" = {
    content = ''
      export LINEAR_API_KEY="${config.sops.placeholder.linear_api_key}"
    '';
  };

  programs.zsh.initContent = ''
    [ -f "${config.sops.templates."linear-env".path}" ] && source "${
      config.sops.templates."linear-env".path
    }"
  '';
}
