{ lib, pkgs, ... }:

let
  installPath = lib.makeBinPath (
    with pkgs;
    [
      bash
      coreutils
      curl
      gnused
      jq
      zstd
    ]
  );
in
{
  # The native install keeps Claude Code's auto-updater on; the Homebrew cask
  # and the Nix package both turn it off.
  home.activation.claudeCode = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -e "$HOME/.local/bin/claude" ]; then
      run env PATH="$HOME/.local/bin:${installPath}:/usr/bin:/bin" \
        bash -euo pipefail -c 'curl -fsSL https://claude.ai/install.sh | bash' \
        || echo "Claude Code install failed; the next rebuild will retry it." >&2
    fi
  '';
}
