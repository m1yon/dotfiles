{
  config,
  pkgs,
  ...
}:

{
  sops.secrets = {
    aws_sso_start_url.sopsFile = ../../secrets/aws.yaml;
    aws_sso_account_id_paradis_dev.sopsFile = ../../secrets/aws.yaml;
    aws_sso_account_id_paradis_prod.sopsFile = ../../secrets/aws.yaml;
  };

  sops.templates."aws-config" = {
    path = "${config.home.homeDirectory}/.aws/config";
    content = ''
      [sso-session meca]
      sso_start_url = ${config.sops.placeholder.aws_sso_start_url}
      sso_region = us-east-1
      sso_registration_scopes = sso:account:access

      [profile paradis_dev]
      sso_session = meca
      sso_account_id = ${config.sops.placeholder.aws_sso_account_id_paradis_dev}
      sso_role_name = AWSAdministratorAccess
      region = us-east-1
      output = json

      [profile paradis_prod]
      sso_session = meca
      sso_account_id = ${config.sops.placeholder.aws_sso_account_id_paradis_prod}
      sso_role_name = AWSAdministratorAccess
      region = us-east-1
      output = json
    '';
  };

  programs.awscli = {
    enable = true;
    package = pkgs.awscli2;
  };
}
