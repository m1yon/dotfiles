#!/usr/bin/env bash
set -euo pipefail

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    printf 'Missing required command: %s\n' "$1" >&2
    exit 1
  fi
}

ensure_sops_age_key() {
  local ssh_key="${HOME}/.ssh/id_ed25519"
  local age_key_dir="${XDG_CONFIG_HOME:-${HOME}/.config}/sops/age"
  local age_key_file="${age_key_dir}/keys.txt"

  if [ -s "$age_key_file" ]; then
    printf 'SOPS age key already exists: %s\n' "$age_key_file"
    return
  fi

  if [ ! -f "$ssh_key" ]; then
    printf 'SSH private key not found: %s\n' "$ssh_key" >&2
    exit 1
  fi

  require_command nix

  printf 'Generating SOPS age key: %s\n' "$age_key_file"
  mkdir -p "$age_key_dir"
  chmod 700 "$age_key_dir"
  umask 077
  nix --extra-experimental-features 'nix-command flakes' shell nixpkgs#ssh-to-age -c ssh-to-age -private-key -i "$ssh_key" > "$age_key_file"
}

onedrive_reauth() {
  local name="$1"

  require_command systemctl
  require_command onedrive

  printf 'Re-authenticating OneDrive instance: %s\n' "$name"
  systemctl --user stop "onedrive-${name}"
  onedrive --confdir="${HOME}/.config/onedrive-${name}" --reauth --sync
  systemctl --user start "onedrive-${name}"
}

ensure_sops_age_key

case "$(uname -s)" in
  Darwin)
    ;;
  Linux)
    onedrive_reauth personal
    onedrive_reauth carecoordinators
    ;;
  *)
    printf 'Unsupported OS: %s\n' "$(uname -s)" >&2
    exit 1
    ;;
esac
