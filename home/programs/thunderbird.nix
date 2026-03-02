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
          "mailnews.start_page.enabled" = false;
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
          "mail.server.server_${id}.using_subscription" = false;
        };
        perIdentitySettings = id: {
          "mail.identity.id_${id}.archive_folder" =
            "imap://michael.lyon%40mecatherapies.com@outlook.office365.com/Archive";
          "mail.identity.id_${id}.archive_granularity" = 0;
          "mail.identity.id_${id}.archive_keep_folder_structure" = false;
          "mail.identity.id_${id}.archives_folder_picker_mode" = "1";
        };
        messageFilters = [
          {
            name = "Events";
            enabled = true;
            type = "17";
            action = "Move to folder";
            actionValue = "imap://michael.lyon%40mecatherapies.com@outlook.office365.com/Events";
            condition = "OR (body,contains,path=/calendar/item) OR (body,contains,Join with Google Meet)";
          }
          {
            name = "Microsoft";
            enabled = true;
            type = "17";
            action = "Move to folder";
            actionValue = "imap://michael.lyon%40mecatherapies.com@outlook.office365.com/Microsoft";
            condition = "OR (from,contains,MSSecurity-noreply@microsoft.com) OR (from,contains,flow-noreply@microsoft.com)";
          }
          {
            name = "AWS";
            enabled = true;
            type = "17";
            action = "Move to folder";
            actionValue = "imap://michael.lyon%40mecatherapies.com@outlook.office365.com/AWS";
            condition = "AND (from,contains,aws.com)";
          }
        ];
      };
    };
  };
}
