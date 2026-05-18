{
  pkgs,
  inputs,
  ...
}:

{
  home.sessionVariables.AGENT_BROWSER_PROFILE = "~/.agent-browser-profile";

  home.packages = [
    inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.agent-browser
  ];
}
