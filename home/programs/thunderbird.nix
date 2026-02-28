{ ... }:

{
  programs.thunderbird = {
    enable = true;
    profiles = {
      default = {
        isDefault = true;
      };
    };
  };

  accounts.email.accounts = {
    personal = {
      primary = true;
      flavor = "gmail.com";
      address = "mlyon360@gmail.com";
      realName = "Michael Lyon";

      thunderbird = {
        enable = true;
        profiles = [ "default" ];
      };
    };

    work = {
      flavor = "outlook.office365.com";
      address = "michael.lyon@mecatherapies.com";
      realName = "Michael Lyon";

      thunderbird = {
        enable = true;
        profiles = [ "default" ];
        settings = id: {
          "mail.smtpserver.smtp_${id}.authMethod" = 10;
          "mail.server.server_${id}.authMethod" = 10;
        };
      };
    };
  };
}
