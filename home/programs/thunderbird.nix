{ ... }:

{
  programs.thunderbird = {
    enable = true;
    profiles = {
      default = {
        isDefault = true;
        settings = {
          "mail.pane_config.dynamic" = 0;
          "mail.threadpane.listview" = 1;
          "extensions.activeThemeID" = "thunderbird-compact-dark@mozilla.org";
          "mail.uifontsize" = 14;
          "font.default.x-western" = "sans-serif";
          "font.name.sans-serif.x-western" = "JetBrains Mono";
          "font.name-list.sans-serif.x-western" = "JetBrains Mono";
          "font.size.variable.x-western" = 14;
          "font.name.monospace.x-western" = "JetBrains Mono";
          "font.name-list.monospace.x-western" = "JetBrains Mono";
          "font.size.monospace.x-western" = 14;
          "font.default.x-unicode" = "sans-serif";
          "font.name.sans-serif.x-unicode" = "JetBrains Mono";
          "font.name-list.sans-serif.x-unicode" = "JetBrains Mono";
          "font.size.variable.x-unicode" = 14;
          "font.name.monospace.x-unicode" = "JetBrains Mono";
          "font.name-list.monospace.x-unicode" = "JetBrains Mono";
          "font.size.monospace.x-unicode" = 14;
        };
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
