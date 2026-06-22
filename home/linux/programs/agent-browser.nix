{
  pkgs,
  inputs,
  ...
}:

let
  agentBrowser = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.agent-browser;
  chrome = "${pkgs.google-chrome}/share/google/chrome/chrome";
in
{
  home.sessionVariables = {
    AGENT_BROWSER_EXECUTABLE_PATH = chrome;
    AGENT_BROWSER_PROFILE = "Profile 2";
  };

  home.packages = [
    (pkgs.writeShellScriptBin "agent-browser" ''
      export AGENT_BROWSER_EXECUTABLE_PATH="${chrome}"
      export AGENT_BROWSER_PROFILE="Profile 2"
      exec "${agentBrowser}/bin/.agent-browser-wrapped" "$@"
    '')
  ];
}
