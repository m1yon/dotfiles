# Usage: todoist-stale-test.sh <path to todoist-stale>

stale="$1"
bin="$(mktemp -d)"
failures=0

{
  printf '#!%s\n' "$BASH"
  cat <<'TD'
case "$*" in
  "task list --json --all --full")
    cat <<'JSON'
{"results": [
  {"id": "quiet", "content": "No events", "projectId": "w", "addedAt": "2000-01-01T00:00:00Z", "labels": [], "due": null},
  {"id": "agent-move", "content": "Only an agent move", "projectId": "w", "addedAt": "2000-01-01T00:00:00Z", "labels": [], "due": null},
  {"id": "app-move", "content": "Moved in the app", "projectId": "w", "addedAt": "2000-01-01T00:00:00Z", "labels": [], "due": null},
  {"id": "marked", "content": "Only marked stale by an agent", "projectId": "w", "addedAt": "2000-01-01T00:00:00Z", "labels": ["stale"], "due": null},
  {"id": "triaged", "content": "Agent priority change", "projectId": "w", "addedAt": "2000-01-01T00:00:00Z", "labels": [], "due": null},
  {"id": "kept", "content": "Stale label removed", "projectId": "w", "addedAt": "2000-01-01T00:00:00Z", "labels": [], "due": null},
  {"id": "unfrogged", "content": "Only frog removed", "projectId": "w", "addedAt": "2000-01-01T00:00:00Z", "labels": [], "due": null},
  {"id": "waiting", "content": "Waiting added", "projectId": "w", "addedAt": "2000-01-01T00:00:00Z", "labels": ["waiting"], "due": null},
  {"id": "rescheduled", "content": "Marked stale and rescheduled", "projectId": "w", "addedAt": "2000-01-01T00:00:00Z", "labels": ["stale"], "due": {"date": "2000-02-01", "isRecurring": false}},
  {"id": "commented", "content": "Commented in the app", "projectId": "w", "addedAt": "2000-01-01T00:00:00Z", "labels": [], "due": null},
  {"id": "parent", "content": "Subtask completed", "projectId": "w", "addedAt": "2000-01-01T00:00:00Z", "labels": [], "due": null},
  {"id": "someday", "content": "In Someday", "projectId": "sd", "addedAt": "2000-01-01T00:00:00Z", "labels": [], "due": null},
  {"id": "recurring", "content": "Recurring", "projectId": "w", "addedAt": "2000-01-01T00:00:00Z", "labels": [], "due": {"date": "2000-01-03", "isRecurring": true}},
  {"id": "new", "content": "Added after the cutoff", "projectId": "w", "addedAt": "2999-01-01T00:00:00Z", "labels": [], "due": null}
], "nextCursor": null}
JSON
    ;;
  "project list --json --all")
    cat <<'JSON'
{"results": [
  {"id": "w", "name": "Work", "parentId": null},
  {"id": "sd", "name": "Someday", "parentId": null}
], "nextCursor": null}
JSON
    ;;
  "activity --since "????-??-??" --json --limit 1000")
    cat <<'JSON'
{"results": [
  {"objectType": "task", "eventType": "moved", "objectId": "agent-move", "parentItemId": null, "extraData": {"client": "todoist-cli/5.10.0", "content": "Only an agent move", "noteCount": 0, "sourceProjectId": "x", "destinationProjectId": "w"}},
  {"objectType": "task", "eventType": "updated", "objectId": "marked", "parentItemId": null, "extraData": {"client": "Claude", "content": "Only marked stale by an agent", "noteCount": 0, "labels": ["stale"], "lastLabels": null}},
  {"objectType": "task", "eventType": "moved", "objectId": "triaged", "parentItemId": null, "extraData": {"client": "todoist-cli/5.10.0", "content": "Agent priority change", "noteCount": 0, "sourceProjectId": "x", "destinationProjectId": "w"}},
  {"objectType": "task", "eventType": "updated", "objectId": "triaged", "parentItemId": null, "extraData": {"client": "todoist-cli/5.10.0", "content": "Agent priority change", "noteCount": 0, "priority": "p2", "lastPriority": "p4"}},
  {"objectType": "task", "eventType": "updated", "objectId": "kept", "parentItemId": null, "extraData": {"client": "todoist-cli/5.10.0", "content": "Stale label removed", "noteCount": 0, "labels": [], "lastLabels": ["stale"]}},
  {"objectType": "task", "eventType": "updated", "objectId": "unfrogged", "parentItemId": null, "extraData": {"client": "todoist-cli/5.10.0", "content": "Only frog removed", "noteCount": 0, "labels": [], "lastLabels": ["frog"]}}
], "nextCursor": "page-2"}
JSON
    ;;
  "activity --since "????-??-??" --json --limit 1000 --cursor page-2")
    case ${FAKE_TD_ACTIVITY:-} in
      fail) exit 1 ;;
      no-results) echo '{"error": "Service Unavailable"}' && exit 0 ;;
      empty) exit 0 ;;
    esac
    cat <<'JSON'
{"results": [
  {"objectType": "task", "eventType": "moved", "objectId": "agent-move", "parentItemId": null, "extraData": {"client": "Bun/1.4.4", "content": "Only an agent move", "noteCount": 0, "sourceProjectId": "w", "destinationProjectId": "x"}},
  {"objectType": "task", "eventType": "moved", "objectId": "app-move", "parentItemId": null, "extraData": {"client": "Todoist v12137 (macOS)", "content": "Moved in the app", "noteCount": 0, "sourceProjectId": "x", "destinationProjectId": "w"}},
  {"objectType": "task", "eventType": "updated", "objectId": "waiting", "parentItemId": null, "extraData": {"client": "todoist-cli/5.10.0", "content": "Waiting added", "noteCount": 0, "labels": ["waiting"], "lastLabels": null}},
  {"objectType": "task", "eventType": "updated", "objectId": "rescheduled", "parentItemId": null, "extraData": {"client": "todoist-cli/5.10.0", "content": "Marked stale and rescheduled", "noteCount": 0, "labels": ["stale"], "lastLabels": null, "dueDate": "2000-02-01", "lastDueDate": "2000-01-15"}},
  {"objectType": "comment", "eventType": "added", "objectId": "note-1", "parentItemId": "commented", "extraData": {"client": "Todoist v26.11.5 (iOS 27.2.0)", "content": "Called them", "noteCount": 1}},
  {"objectType": "task", "eventType": "completed", "objectId": "child", "parentItemId": null, "extraData": {"client": "todoist-cli/5.10.0", "content": "Subtask", "noteCount": 0, "parentId": "parent"}}
], "nextCursor": null}
JSON
    ;;
  *) exit 1 ;;
esac
TD
} >"$bin/td"
chmod +x "$bin/td"
export PATH="$bin:$PATH"

check() {
  local name="$1" expected="$2" actual status=0
  actual="$("$stale" </dev/null)" || status=$?
  if [[ $status != 0 ]] || ! actual="$(jq -r '.[] | "\(.id) \(.labels)"' <<<"$actual")" || [[ $actual != "$expected" ]]; then
    printf 'FAIL: %s (exit %s)\n--- expected\n%s\n--- actual\n%s\n' "$name" "$status" "$expected" "$actual" >&2
    failures=$((failures + 1))
  fi
}

check_fails() {
  local name="$1" actual status=0
  actual="$("$stale" </dev/null 2>/dev/null)" || status=$?
  if [[ $status == 0 || -n $actual ]]; then
    printf 'FAIL: %s (exit %s)\n--- expected no output\n--- actual\n%s\n' "$name" "$status" "$actual" >&2
    failures=$((failures + 1))
  fi
}

check "uncounted events leave cards stale, in task list order" 'quiet []
agent-move []
marked ["stale"]
unfrogged []'

FAKE_TD_ACTIVITY=fail check_fails "a failed activity page prints no array"
FAKE_TD_ACTIVITY=no-results check_fails "an activity page without results prints no array"
FAKE_TD_ACTIVITY=empty check_fails "an empty activity page prints no array"

if ((failures > 0)); then
  echo "$failures todoist-stale case(s) failed" >&2
  exit 1
fi
echo "todoist-stale: all cases passed"
