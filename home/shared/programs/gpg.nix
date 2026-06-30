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
  # Set this to a full fingerprint when one imported key should be the default signer.
  defaultKey = null;
in
{
  programs.gpg = {
    enable = true;
    mutableKeys = true;
    mutableTrust = true;

    settings = lib.optionalAttrs (defaultKey != null) {
      default-key = defaultKey;
      local-user = defaultKey;
    };
  };

  sops.secrets = lib.mkIf hasGpgSecrets {
    pgp_private_keys.sopsFile = gpgSecretsFile;
  };

  home.activation.importPgpPrivateKeys = lib.mkIf hasGpgSecrets (
    lib.hm.dag.entryAfter [ "sops-nix" "createGpgHomedir" ] ''
      secret_path="${config.sops.secrets.pgp_private_keys.path}"

      if [ ! -s "$secret_path" ]; then
        echo "Skipping PGP private keys import; secret is empty or missing: $secret_path" >&2
      else
        key_ids="$(
          ${gpg} --batch --show-keys --with-colons "$secret_path" 2>/dev/null \
            | ${pkgs.gawk}/bin/awk -F: '$1 == "sec" || $1 == "sec#" { print $5 }'
        )"
        fingerprints="$(
          ${gpg} --batch --show-keys --with-colons --with-fingerprint "$secret_path" 2>/dev/null \
            | ${pkgs.gawk}/bin/awk -F: '
              $1 == "sec" || $1 == "sec#" { want_fingerprint = 1; next }
              $1 == "fpr" && want_fingerprint { print $10; want_fingerprint = 0 }
            '
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

        if [ -n "$fingerprints" ]; then
          for fingerprint in $fingerprints; do
            printf '%s:6:\n' "$fingerprint"
          done | ${gpg} --batch --import-ownertrust
        fi
      fi
    ''
  );
}
