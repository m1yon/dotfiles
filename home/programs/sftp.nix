{ config, ... }:
{
  sops.secrets = {
    molina_sftp_from_path.sopsFile = ../../secrets/sftp.yaml;
    pres_sftp_from_path.sopsFile = ../../secrets/sftp.yaml;
  };

  sops.templates."sftp-env" = {
    content = ''
      export MOLINA_SFTP_FROM_PATH="${config.sops.placeholder.molina_sftp_from_path}"
      export PRES_SFTP_FROM_PATH="${config.sops.placeholder.pres_sftp_from_path}"
    '';
  };

  programs.zsh.initContent = ''
    [ -f "${config.sops.templates."sftp-env".path}" ] && source "${
      config.sops.templates."sftp-env".path
    }"
  '';
}
