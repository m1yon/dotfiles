{ pkgs, ... }:

let
  version = "1.0.2";

  bdBase = pkgs.buildGoModule {
    pname = "beads";
    inherit version;

    src = pkgs.fetchFromGitHub {
      owner = "gastownhall";
      repo = "beads";
      rev = "v${version}";
      hash = "sha256-aRgm2gWO08FZA2HaVxSitmjDk0Fp51oFZ8lmBCKDrzU=";
    };

    vendorHash = "sha256-stY1JxMAeINT73KCvwZyh/TUktkLirEcGa0sW1u7W1s=";

    subPackages = [ "cmd/bd" ];
    doCheck = false;

    postPatch = ''
      goVer="$(go env GOVERSION | sed 's/^go//')"
      go mod edit -go="$goVer"
    '';

    env.GOTOOLCHAIN = "auto";
    env.CGO_CPPFLAGS = "-I${pkgs.icu.dev}/include";
    env.CGO_LDFLAGS = "-L${pkgs.icu}/lib";

    nativeBuildInputs = [ pkgs.git ];

    meta = {
      description = "beads (bd) - An issue tracker designed for AI-supervised coding workflows";
      homepage = "https://github.com/gastownhall/beads";
      license = pkgs.lib.licenses.mit;
      mainProgram = "bd";
    };
  };

  beads = pkgs.stdenv.mkDerivation {
    pname = "beads";
    inherit version;
    phases = [ "installPhase" ];
    installPhase = ''
      mkdir -p $out/bin $out/share/fish/vendor_completions.d \
        $out/share/bash-completion/completions $out/share/zsh/site-functions
      cp ${bdBase}/bin/bd $out/bin/bd
      ln -s bd $out/bin/beads
      $out/bin/bd completion fish > $out/share/fish/vendor_completions.d/bd.fish
      $out/bin/bd completion bash > $out/share/bash-completion/completions/bd
      $out/bin/bd completion zsh > $out/share/zsh/site-functions/_bd
    '';
    meta = bdBase.meta;
  };
in
{
  home.packages = [ beads ];
}
