---
name: sops
description: Manage SOPS-encrypted secrets in this NixOS dotfiles repo. Covers adding new secrets, editing existing ones, and wiring them into Nix modules via sops-nix (sops.secrets, sops.templates, placeholders). Use when user mentions sops, secrets, encrypted files, API keys, credentials, or wants to add a new service that needs secrets.
---

# SOPS Secrets Management

## Architecture

- Encrypted files live in `secrets/` (YAML or binary)
- `.sops.yaml` defines creation rules — age key derived from `~/.ssh/id_ed25519`
- `home/programs/sops.nix` configures sops-nix with the SSH key path
- Each service's Nix module declares its own `sops.secrets` and `sops.templates`

## Adding a new secret (full workflow)

### 1. Tell the user to add the secret value

You cannot decrypt or edit SOPS files directly. Instruct the user:

```
task sops-edit -- <filename>.yaml
```

For a new file, ensure a matching `path_regex` exists in `.sops.yaml` (the default rule covers `secrets/*.yaml`).

### 2. Declare secrets in the Nix module

```nix
sops.secrets = {
  my_secret_key.sopsFile = ../../secrets/<filename>.yaml;
};
```

Each YAML key becomes a separate `sops.secrets` entry, all pointing to the same `sopsFile`.

### 3. Wire secrets into config via templates

**For config files** (e.g. `~/.config/foo/config.toml`):

```nix
sops.templates."foo-config" = {
  path = "${config.home.homeDirectory}/.config/foo/config.toml";
  content = ''
    api_key = ${config.sops.placeholder.my_secret_key}
  '';
};
```

**For environment variables** (sourced in zsh):

```nix
sops.templates."foo-env" = {
  content = ''
    export FOO_API_KEY="${config.sops.placeholder.my_secret_key}"
  '';
};

programs.zsh.initContent = ''
  [ -f "${config.sops.templates."foo-env".path}" ] && source "${
    config.sops.templates."foo-env".path
  }"
'';
```

**For JSON config** (e.g. MCP servers):

```nix
sops.templates."foo.json" = {
  path = "${config.home.homeDirectory}/.config/foo.json";
  content = builtins.toJSON {
    apiKey = config.sops.placeholder.my_secret_key;
  };
};
```

### 4. Rebuild

Tell the user to run `task rebuild` or `task rebuild-home`.

## Editing existing secrets

Instruct the user to run:

```
task sops-edit -- <filename>.yaml
```

Existing files: `aws.yaml`, `linear.yaml`, `onedrive.yaml`, `sftp.yaml`, `xero.yaml`, `ssh_config`.

## Key rules

- **Never** hardcode secrets in Nix files — always use `sops.placeholder`
- **Never** attempt to decrypt SOPS files — the user must run `task sops-edit` interactively
- Secret names in `sops.secrets` must match the YAML key names in the encrypted file
- One YAML file per service/tool is the convention
- The `sopsFile` path is relative to the Nix module file (use `../../secrets/`)
