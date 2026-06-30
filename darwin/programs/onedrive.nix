{ username, ... }:

{
  homebrew.casks = [ "onedrive" ];

  home-manager.users.${username} =
    { ... }:
    {
      # Add compatibility links here after OneDrive creates the real
      # ~/Library/CloudStorage paths.
    };
}
