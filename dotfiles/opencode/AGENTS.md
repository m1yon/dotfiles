**IMPORTANT**: do NOT add comments to code unless explicitly told by the user.
- This is a PURE Nix system. NEVER install packages with `brew`, `nix profile`, language-specific package managers, app installers, manual downloads, or any other imperative install path.
- For package changes, settings changes, services, apps, casks, defaults, or system behavior, edit the Nix flake/modules only, then run the repo rebuild flow.
- Do not edit system or app settings manually through GUIs, `defaults write`, direct config-file mutation outside the Nix-managed files, or vendor CLIs. Make the desired state declarative in Nix.
- Homebrew is allowed only as a nix-darwin/nix-homebrew backend declared in the flake. Do not call the `brew` CLI to install, remove, upgrade, or mutate packages.
- Do NOT use the question tool when the grill-me or grill-with-docs skill is loaded.
