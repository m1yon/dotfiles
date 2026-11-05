{
  imports = [
    ./codex.nix
    ./onedrive.nix
    ./orchestrator.nix
    ./remote-desktop.nix
  ];

  services.orchestrator.mode = "live";
}
