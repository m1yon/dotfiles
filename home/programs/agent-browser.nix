{
  pkgs,
  config,
  inputs,
  ...
}:

{
  home.packages = [
    inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.agent-browser
  ];

  home.sessionVariables = {
    AGENT_BROWSER_PROFILE = "${config.home.homeDirectory}/.agent-browser-profiles/agent-browser";
  };
}
