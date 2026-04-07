{
  config,
  pkgs,
  nixConfigDir,
  ...
}:

let
  dotfiles = "${nixConfigDir}/dotfiles";
  outOfStore = config.lib.file.mkOutOfStoreSymlink;

  lazycommit = pkgs.buildGoModule rec {
    pname = "lazycommit";
    version = "1.4.0";

    src = pkgs.fetchFromGitHub {
      owner = "m7medVision";
      repo = "lazycommit";
      rev = "v${version}";
      hash = "sha256-DD3DXTev8WHNkAYDrPY2PISuA8WwKuK0GCLebpn01Rg=";
    };

    vendorHash = "sha256-4OPCUWXxsAnzxsqZPHhjvhxQQf5Knm7nGqrdjH4I4YY=";

    doCheck = false;
  };
in
{
  home.packages = [ lazycommit ];

  home.file = {
    ".config/.lazycommit.yaml".source = outOfStore "${dotfiles}/lazycommit/.lazycommit.yaml";
  };
}
