{
  config,
  lib,
  pkgs,
  ...
}:
let
  tokenFile = config.sops.secrets.todoist_api_token.path;
in
{
  # Agents run td from shells that never read .zshrc, so td reads its own token.
  # An exported token would also reach every other process those shells start.
  home.packages = [
    (pkgs.writeShellApplication {
      name = "td";
      runtimeInputs = [
        pkgs.curl
        pkgs.jq
      ];
      text = ''
        if [ -z "''${TODOIST_API_TOKEN:-}" ] && [ -r "${tokenFile}" ]; then
          TODOIST_API_TOKEN=$(<"${tokenFile}")
          export TODOIST_API_TOKEN
        fi

        # td has no command for the order of cards in Today, which /morning-pick
        # sets so the frog comes first. `td day-order id:a id:b` puts a, then b, at
        # the top of Today.
        if [ "''${1:-}" = day-order ]; then
          shift
          if [ "$#" -eq 0 ]; then
            echo "usage: td day-order id:<id>..." >&2
            exit 2
          fi
          commands=$(jq -cn --arg uuid "day-order-$(date +%s)-$$" '[{
            type: "item_update_day_orders",
            uuid: $uuid,
            args: {ids_to_orders: ($ARGS.positional | map(ltrimstr("id:")) | to_entries | map({key: .value, value: (.key + 1)}) | from_entries)}
          }]' --args "$@")
          # The header comes in on stdin so the token never shows in argv.
          printf 'header = "Authorization: Bearer %s"\n' "''${TODOIST_API_TOKEN:?}" |
            curl --silent --show-error --fail --max-time 30 --config - \
              --data-urlencode "commands=$commands" https://api.todoist.com/api/v1/sync |
            jq -e '.sync_status | to_entries | all(.value == "ok")' >/dev/null
          exit
        fi

        exec ${lib.getExe (pkgs.callPackage ../pkgs/todoist-cli { })} "$@"
      '';
    })
  ];

  sops.secrets = {
    todoist_api_token.sopsFile = ../../../secrets/todoist.yaml;
  };
}
