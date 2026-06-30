{
  config,
  lib,
  pkgs,
  ...
}:

let
  gpgSecretsFile = ../../../secrets/gpg.yaml;
  hasGpgSecrets = builtins.pathExists gpgSecretsFile;
  gpg = "${config.programs.gpg.package}/bin/gpg";
in
{
  programs.gpg = {
    enable = true;
  };

  sops.secrets = lib.mkIf hasGpgSecrets {
    pgp_private_key.sopsFile = gpgSecretsFile;
  };

  home.activation.importPgpPrivateKey = lib.mkIf hasGpgSecrets (
    lib.hm.dag.entryAfter [ "sops-nix" "createGpgHomedir" ] ''
      secret_path="${config.sops.secrets.pgp_private_key.path}"

      if [ ! -s "$secret_path" ]; then
        echo "Skipping PGP private key import; secret is empty or missing: $secret_path" >&2
      else
        key_ids="$(
          ${gpg} --batch --show-keys --with-colons "$secret_path" 2>/dev/null \
            | ${pkgs.gawk}/bin/awk -F: '$1 == "sec" || $1 == "sec#" { print $5 }'
        )"

        needs_import=1
        if [ -n "$key_ids" ]; then
          needs_import=0
          for key_id in $key_ids; do
            if ! ${gpg} --batch --list-secret-keys "$key_id" >/dev/null 2>&1; then
              needs_import=1
              break
            fi
          done
        fi

        if [ "$needs_import" -eq 1 ]; then
          ${gpg} --batch --import "$secret_path"
        fi
      fi
    ''
  );
}
