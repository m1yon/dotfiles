{ username, ... }:

{
  imports = [
    ../shared
  ];

  home.username = username;
  home.stateVersion = "25.11";
}
