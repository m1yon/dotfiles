{ config, ... }:
{
  sops.secrets = {
    openai_api_key.sopsFile = ../../secrets/openai.yaml;
  };

  sops.templates."openai-env" = {
    content = ''
      export OPENAI_API_KEY="${config.sops.placeholder.openai_api_key}"
    '';
  };

  programs.zsh.initContent = ''
    [ -f "${config.sops.templates."openai-env".path}" ] && source "${
      config.sops.templates."openai-env".path
    }"
  '';
}
