{ username, ... }:

{
  homebrew.casks = [ "onedrive" ];

  home-manager.users.${username} =
    { config, ... }:
    let
      outOfStore = config.lib.file.mkOutOfStoreSymlink;
      cloud = "${config.home.homeDirectory}/Library/CloudStorage";

      workOneDriveRoot = "${cloud}/OneDrive-MecaTherapiesLLC";
      careCoordinatorsRoot = "${workOneDriveRoot}/Care Coordinators - Documents";
      reportingRoot = "${workOneDriveRoot}/Reporting - Documents";
    in
    {
      home.file = {
        "OneDrive/personal".source = outOfStore workOneDriveRoot;
        "OneDrive/carecoordinators".source = outOfStore careCoordinatorsRoot;
        "OneDrive/reporting".source = outOfStore reportingRoot;
      };
    };
}
