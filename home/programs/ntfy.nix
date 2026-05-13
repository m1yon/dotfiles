{ config, ... }:
{
  sops.secrets = {
    ntfy_auth_token.sopsFile = ../../secrets/ntfy.yaml;
  };

  sops.templates."ntfy-env" = {
    content = ''
      export NTFY_AUTH_TOKEN="${config.sops.placeholder.ntfy_auth_token}"
    '';
  };

  programs.zsh.initContent = ''
    [ -f "${config.sops.templates."ntfy-env".path}" ] && source "${
      config.sops.templates."ntfy-env".path
    }"
  '';
}
