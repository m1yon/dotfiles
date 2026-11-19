# Prints the weekly review's stale cards as one JSON array of {id, content, labels}:
# open cards outside Someday, not recurring, added before the cutoff 21 days ago,
# that no counted event in the activity log has touched since the cutoff.

since="$(date -d '21 days ago' +%F)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

fetch() {
  local out="$1"
  shift
  td "$@" >"$out"
  if ! jq -e '.results | type == "array"' "$out" >/dev/null 2>&1; then
    echo "todoist-stale: td $* returned no results" >&2
    exit 1
  fi
}

fetch "$tmp/tasks" task list --json --all --full
fetch "$tmp/projects" project list --json --all

: >"$tmp/events"
cursor=()
while :; do
  fetch "$tmp/page" activity --since "$since" --json --limit 1000 "${cursor[@]}"
  jq -c '.results[]' "$tmp/page" >>"$tmp/events"
  next="$(jq -r '.nextCursor // empty' "$tmp/page")"
  if [[ -z $next ]]; then break; fi
  cursor=(--cursor "$next")
done

# shellcheck disable=SC2016 # These are jq variables, not shell expansions.
jq -n \
  --arg since "$since" \
  --slurpfile tasks "$tmp/tasks" \
  --slurpfile projects "$tmp/projects" \
  --slurpfile events "$tmp/events" '
  def move_outside_apps:
    .eventType == "moved" and (.extraData.client // "" | startswith("Todoist ") | not);
  def marking_label_change:
    .eventType == "updated"
    and (.extraData | keys - ["client", "content", "noteCount", "labels", "lastLabels"] == [])
    and ((.extraData.labels // []) as $now | (.extraData.lastLabels // []) as $before
      | [$now - $before, $before - $now]
      | IN([["stale"], []], [["frog"], []], [[], ["frog"]]));
  def touched_card:
    if .objectType == "task" then
      .objectId, (select(.eventType == "completed") | .extraData.parentId // empty)
    elif .objectType == "comment" then .parentItemId // empty
    else empty end;

  [$projects[0].results[] | select(.name == "Someday") | .id] as $someday
  | [$events[] | select(move_outside_apps or marking_label_change | not) | touched_card] as $active
  | [$tasks[0].results[]
    | select(.projectId | IN($someday[]) | not)
    | select(.due.isRecurring != true)
    | select(.addedAt < $since)
    | select(.id | IN($active[]) | not)
    | {id, content, labels}]
'
