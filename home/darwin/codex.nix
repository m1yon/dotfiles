{ lib, pkgs, ... }:

let
  installPath = lib.makeBinPath (
    with pkgs;
    [
      coreutils
      curl
    ]
  );
in
{
  # The native install keeps Codex CLI's auto-updater on; the Nix package is
  # pinned to the llm-agents flake input and falls behind between flake updates.
  home.activation.codexCli = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -e "$HOME/.local/bin/codex" ]; then
      run env PATH="$HOME/.local/bin:${installPath}:/usr/bin:/bin" CODEX_NON_INTERACTIVE=1 \
        /bin/sh -c 'set -eu; curl -fsSL https://chatgpt.com/codex/install.sh | sh' \
        || echo "Codex CLI install failed; the next rebuild will retry it." >&2
    fi
  '';
}
