{ lib, pkgs, ... }:

let
  installPath = lib.makeBinPath (
    with pkgs;
    [
      bash
      coreutils
      curl
      findutils
      gawk
      gnugrep
      gnused
      gnutar
      gzip
      jq
      openssl
      which
      zstd
    ]
  );
in
{
  # The native installs keep each CLI's auto-updater on. Nix only bootstraps
  # them, and they update themselves in ~/.local afterwards.
  home.activation.agentClis = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -e "$HOME/.local/bin/claude" ]; then
      run env PATH="$HOME/.local/bin:${installPath}:/usr/bin:/bin" \
        bash -euo pipefail -c 'curl -fsSL https://claude.ai/install.sh | bash' \
        || echo "Claude Code install failed; the next rebuild will retry it." >&2
    fi

    if [ ! -e "$HOME/.local/bin/codex" ]; then
      run env PATH="$HOME/.local/bin:${installPath}:/usr/bin:/bin" CODEX_NON_INTERACTIVE=1 \
        /bin/sh -c 'set -eu; curl -fsSL https://chatgpt.com/codex/install.sh | sh' \
        || echo "Codex CLI install failed; the next rebuild will retry it." >&2
    fi
  '';
}
