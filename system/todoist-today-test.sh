# Usage: todoist-today-test.sh <path to todoist-today>

hook="$1"
bin="$(mktemp -d)"
failures=0

{
  printf '#!%s\n' "$BASH"
  cat <<'TD'
if [[ -n ${FAKE_TD_FAIL:-} ]]; then exit 1; fi
case "$*" in
  "project list --json --all")
    cat <<'JSON'
{"results": [
  {"id": "m", "name": "MECA", "parentId": null},
  {"id": "a", "name": "Appointment sync", "parentId": "m"},
  {"id": "s", "name": "Side Projects", "parentId": null},
  {"id": "p", "name": "Personal", "parentId": null},
  {"id": "r", "name": "Routines", "parentId": null}
], "nextCursor": null}
JSON
    ;;
  "today --json --full --all")
    cat <<'JSON'
{"results": [
  {"id": "t0", "content": "Meditate", "priority": 1, "projectId": "r", "dayOrder": -1},
  {"id": "t5", "content": "Renew the domain", "priority": 2, "projectId": "s", "dayOrder": -1},
  {"id": "t2", "content": "Answer the billing export question", "priority": 4, "projectId": "m", "dayOrder": 4},
  {"id": "t3", "content": "Book a dentist appointment", "priority": 3, "projectId": "p", "dayOrder": 6},
  {"id": "t1", "content": "Fix appointment sync retries", "priority": 3, "projectId": "a", "dayOrder": 2}
], "nextCursor": null}
JSON
    ;;
  "task list --filter @waiting --json --all")
    cat <<'JSON'
{"results": [
  {"id": "w1", "content": "Get the vendor's answer on export limits", "priority": 2, "projectId": "m"},
  {"id": "w2", "content": "Hear back from the landlord", "priority": 2, "projectId": "p"}
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
  actual="$("$hook" </dev/null)" || status=$?
  if [[ $status != 0 || $actual != "$expected" ]]; then
    printf 'FAIL: %s (exit %s)\n--- expected\n%s\n--- actual\n%s\n' "$name" "$status" "$expected" "$actual" >&2
    failures=$((failures + 1))
  fi
}

check "work cards in Today's order, frog first" "Today:
1. Fix appointment sync retries [p2] (MECA › Appointment sync) id:t1
2. Answer the billing export question [p1] (MECA) id:t2
3. Renew the domain [p3] (Side Projects) id:t5
Waiting:
- Get the vendor's answer on export limits [p3] (MECA) id:w1"

FAKE_TD_FAIL=1 check "td failure prints nothing" ""

if ((failures > 0)); then
  echo "$failures todoist-today case(s) failed" >&2
  exit 1
fi
echo "todoist-today: all cases passed"
