{
  config,
  pkgs,
  ...
}:

let
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

  sops.secrets = {
    opencode_zen_api_key.sopsFile = ../../../secrets/github.yaml;
  };

  sops.templates.".lazycommit.yaml" = {
    path = "${config.home.homeDirectory}/.config/.lazycommit.yaml";
    content = ''
      active_provider: openai
      providers:
        openai:
          api_key: "${config.sops.placeholder.opencode_zen_api_key}"
          model: "claude-haiku-4-5"
          endpoint_url: "https://opencode.ai/zen/v1"
          num_suggestions: 5
    '';
  };
}
