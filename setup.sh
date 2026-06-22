#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

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
    printf 'Missing SOPS identity for this machine.\n' >&2
    printf 'Copy one of these from an already-authorized machine, then rerun setup:\n' >&2
    printf '  %s\n' "$age_key_file" >&2
    printf '  %s\n' "$ssh_key" >&2
    printf 'A newly generated key will not decrypt the existing secrets until the secrets are rekeyed for it.\n' >&2
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

install_nix_darwin() {
  local host="${DARWIN_FLAKE_HOST:-macbook}"
  local flake="${script_dir}#${host}"
  local darwin_rebuild

  require_command nix
  require_command sudo

  if darwin_rebuild="$(command -v darwin-rebuild 2>/dev/null)"; then
    printf 'Activating nix-darwin configuration: %s\n' "$flake"
    sudo "$darwin_rebuild" switch --flake "$flake"
    return
  fi

  printf 'Installing nix-darwin configuration: %s\n' "$flake"
  sudo nix --extra-experimental-features 'nix-command flakes' run github:nix-darwin/nix-darwin/nix-darwin-25.11#darwin-rebuild -- switch --flake "$flake"
}

run_rebuild_task() {
  require_command nix

  printf 'Running final rebuild task\n'
  nix --extra-experimental-features 'nix-command flakes' shell nixpkgs#go-task -c task --dir "$script_dir" rebuild
}

ensure_sops_age_key

case "$(uname -s)" in
  Darwin)
    install_nix_darwin
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

run_rebuild_task
