{ pkgs, ... }:

let
  bv = pkgs.buildGoModule rec {
    pname = "bv";
    version = "0.15.2";

    src = pkgs.fetchFromGitHub {
      owner = "Dicklesworthstone";
      repo = "beads_viewer";
      rev = "v${version}";
      hash = "sha256-sdlw9Zr+/I1/PaX0Wpim+UGPxvP7hPrlJ0MTGC20Q5w=";
    };

    vendorHash = null;

    subPackages = [ "cmd/bv" ];
    doCheck = false;

    env.CGO_CFLAGS = "-DSQLITE_ENABLE_FTS5";

    meta = {
      description = "Graph-aware TUI for the Beads issue tracker";
      homepage = "https://github.com/Dicklesworthstone/beads_viewer";
      license = pkgs.lib.licenses.mit;
      mainProgram = "bv";
    };
  };
in
{
  home.packages = [ bv ];
}
