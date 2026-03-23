{
  pkgs,
  ...
}:

let
  tbkeys-lite = pkgs.stdenvNoCC.mkDerivation {
    pname = "tbkeys-lite";
    version = "2.4.3";
    src = pkgs.fetchurl {
      url = "https://addons.thunderbird.net/thunderbird/downloads/file/1044591/tbkeys_lite-2.4.3-tb.xpi";
      hash = "sha256-Qs3+ro5Og3JaREKIHA8A/0dZqgPc19cdVaIABY4qFlA=";
    };
    dontUnpack = true;
    installPhase = ''
      install -D "$src" "$out/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}/tbkeys-lite@addons.thunderbird.net.xpi"
    '';
  };
in
{
  programs.thunderbird = {
    enable = true;
    profiles = {
      default = {
        isDefault = true;
        extensions = [ tbkeys-lite ];
        settings = {
          "extensions.autoDisableScopes" = 0;
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
        settings = id: {
          "mail.server.server_${id}.using_subscription" = false;
        };
        messageFilters = [
          {
            name = "Socials";
            enabled = true;
            type = "17";
            action = "Move to folder";
            actionValue = "imap://mlyon360%40gmail.com@imap.gmail.com/Socials";
            condition = "OR (from,contains,@github.com) OR (from,contains,@linkedin.com) OR (from,contains,@facebookmail.com) OR (from,contains,@x.com) OR (from,contains,@twitter.com) OR (from,contains,@mail.instagram.com) OR (from,contains,@redditmail.com) OR (from,contains,@discord.com) OR (from,contains,@youtube.com) OR (subject,contains,started following) OR (subject,contains,commented on) OR (subject,contains,liked your) OR (subject,contains,mentioned you) OR (subject,contains,replied to) OR (subject,contains,tagged you) OR (subject,contains,shared a post) OR (subject,contains,friend request) OR (subject,contains,connected with) OR (subject,contains,new follower)";
          }
          {
            name = "Transactions";
            enabled = true;
            type = "17";
            action = "Move to folder";
            actionValue = "imap://mlyon360%40gmail.com@imap.gmail.com/Transactions";
            condition = "OR (from,contains,@amazon.com) OR (from,contains,@venmo.com) OR (from,contains,@paypal.com) OR (from,contains,@chase.com) OR (from,contains,@capitalone.com) OR (from,contains,@discover.com) OR (from,contains,@americanexpress.com) OR (from,contains,@bankofamerica.com) OR (from,contains,@wellsfargo.com) OR (from,contains,@usbank.com) OR (from,contains,@citi.com) OR (from,contains,@citibank.com) OR (from,contains,@ally.com) OR (from,contains,@mint.com) OR (from,contains,@ups.com) OR (from,contains,@fedex.com) OR (from,contains,@usps.com) OR (from,contains,@dhl.com) OR (from,contains,@shopify.com) OR (from,contains,@square.com) OR (from,contains,@stripe.com) OR (from,contains,@netflix.com) OR (from,contains,@spotify.com) OR (from,contains,@apple.com) OR (subject,contains,order confirmation) OR (subject,contains,your receipt) OR (subject,contains,payment received) OR (subject,contains,shipping confirmation) OR (subject,contains,has shipped) OR (subject,contains,out for delivery) OR (subject,contains,was delivered) OR (subject,contains,tracking number) OR (subject,contains,your invoice) OR (subject,contains,billing statement) OR (subject,contains,payment due) OR (subject,contains,your statement) OR (subject,contains,refund) OR (subject,contains,subscription renewed) OR (subject,contains,transaction alert) OR (subject,contains,shipped)";
          }
          {
            name = "News";
            enabled = true;
            type = "17";
            action = "Move to folder";
            actionValue = "imap://mlyon360%40gmail.com@imap.gmail.com/News";
            condition = "OR (from,contains,@nytimes.com) OR (from,contains,@cnn.com) OR (from,contains,@bbc.com) OR (from,contains,@washingtonpost.com) OR (from,contains,@reuters.com) OR (from,contains,@apnews.com) OR (from,contains,@theguardian.com) OR (from,contains,@wsj.com) OR (from,contains,@nbcnews.com) OR (from,contains,@abcnews.com) OR (from,contains,@foxnews.com) OR (from,contains,@npr.org) OR (from,contains,@politico.com) OR (from,contains,@axios.com) OR (subject,contains,breaking news) OR (subject,contains,daily briefing) OR (subject,contains,news alert)";
          }
          {
            name = "Blogs";
            enabled = true;
            type = "17";
            action = "Move to folder";
            actionValue = "imap://mlyon360%40gmail.com@imap.gmail.com/Blogs";
            condition = "OR (from,contains,@substack.com) OR (from,contains,@medium.com) OR (from,contains,@beehiiv.com) OR (from,contains,@buttondown.email) OR (from,contains,@ghost.io) OR (subject,contains,new post) OR (subject,contains,published a new) OR (subject,contains,weekly newsletter)";
          }
          {
            name = "Advertisements";
            enabled = true;
            type = "17";
            action = "Move to folder";
            actionValue = "imap://mlyon360%40gmail.com@imap.gmail.com/Advertisements";
            condition = "OR (subject,contains,% off) OR (subject,contains,sale) OR (subject,contains,deal) OR (subject,contains,limited time) OR (subject,contains,promo code) OR (subject,contains,coupon) OR (subject,contains,discount) OR (subject,contains,free shipping) OR (subject,contains,exclusive offer) OR (subject,contains,don't miss) OR (subject,contains,clearance) OR (subject,contains,save now)";
          }
        ];
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
