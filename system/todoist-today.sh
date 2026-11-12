# SessionStart hook for Claude Code and Codex. Both harnesses add its stdout to the
# session's context, so each agent session starts with Michael's work cards for the day.

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

td today --json --full --all >"$tmp/today" 2>/dev/null &
today=$!
td task list --filter "@waiting" --json --all >"$tmp/waiting" 2>/dev/null &
waiting=$!
td filter view Next --json --all --full >"$tmp/next" 2>/dev/null &
next=$!
td project list --json --all >"$tmp/projects" 2>/dev/null &
projects=$!
wait "$today" && wait "$waiting" && wait "$next" && wait "$projects" || exit 0

# Only MECA, Side Projects and their child projects hold work cards. Today's order is
# dayOrder, which /morning-pick sets so the frog comes first. A card nobody ordered has
# dayOrder -1 and goes last.
# shellcheck disable=SC2016 # These are jq variables, not shell expansions.
jq -nr \
  --slurpfile today "$tmp/today" \
  --slurpfile waiting "$tmp/waiting" \
  --slurpfile next "$tmp/next" \
  --slurpfile projects "$tmp/projects" '
  ($projects[0].results | map({key: .id, value: .}) | from_entries) as $byId
  | def project_path($id):
      $byId[$id] as $project
      | if $project == null then []
        elif $project.parentId then project_path($project.parentId) + [$project.name]
        else [$project.name] end;
    def work: select(project_path(.projectId)[0] | IN("MECA", "Side Projects"));
    def line: "\(if any(.labels[]?; . == "frog") then "🐸 " else "" end)\(.content) [\(.priority)] (\(project_path(.projectId) | join(" › "))) id:\(.id)";
  "Today:",
  ([$today[0].results[] | work]
    | sort_by(if .dayOrder < 0 then infinite else .dayOrder end)
    | if length == 0 then "(no work cards)" else to_entries[] | "\(.key + 1). \(.value | line)" end),
  ([$next[0].results[].id] as $nextIds
    | "Open picks: \([$today[0].results[] | select(.id | IN($nextIds[]))] | length) of 5"),
  "Waiting:",
  ([$waiting[0].results[] | work]
    | if length == 0 then "(none)" else .[] | "- \(line)" end)
'
