# PreToolUse hook for Claude Code and Codex. It reads the hook event on stdin and
# exits 2 to block a Bash call; both harnesses show stderr to the agent.
#
# shfmt parses the command into a syntax tree. Every simple command in it, however
# deeply nested, becomes an argv of literal words: quotes removed, backslash escapes
# resolved, and each expansion replaced by expansion_word. The rules read that argv.
# Text that reaches a shell is a script and gets the same check: a shell's -c argument
# or stdin, ssh's remote command, and env -S's string. Every other heredoc is data.
# Input shfmt cannot parse, such as zsh-only syntax, falls back to splitting the text.

# Codex can pass an argument vector, such as ["bash", "-lc", "<script>"].
command="$(jq -r '
  .tool_input.command // ""
  | if type != "array" then .
    elif length >= 3 and (.[0] | tostring | split("/")[-1] | IN("bash", "sh", "zsh", "dash")) and (.[-2] | test("^-l?c$")) then .[-1]
    else map(tostring | @sh) | join(" ")
    end')"

expansion_word='__EXPANSION__'

# shfmt numbers heredocs and here-strings 71 (<<), 72 (<<-) and 73 (<<<).
# shellcheck disable=SC2016 # These are jq variables, not shell expansions.
simple_commands_program='
  def unescape($chars): gsub("\\\\(?<c>[" + $chars + "])"; .c);
  def quoted($chars): [.[] | if .Type == "Lit" then .Value | unescape($chars) else $expansion end] | join("");
  def number($base): reduce (ascii_downcase | explode[] | if . > 96 then . - 87 else . - 48 end) as $digit (0; . * $base + $digit);
  def ansi_c:
    gsub("\\\\(?<e>[0-7]{1,3}|x[0-9A-Fa-f]{1,2}|u[0-9A-Fa-f]{1,4}|U[0-9A-Fa-f]{1,8}|c[\\s\\S]?|[\\s\\S])";
      .e
      | if test("^[0-7]") then [number(8)] | implode
        elif test("^[xuU].") then [.[1:] | number(16)] | implode
        elif startswith("c") then $expansion
        elif test("^[\\\\\"?\\x27]$") then .
        else {n: 10, t: 9, r: 13, a: 7, b: 8, e: 27, E: 27, f: 12, v: 11}[.] as $code
          | if $code then [$code] | implode else "\\" + . end
        end)
    | sub("\\x00[\\s\\S]*"; "");
  def part:
    if .Type == "Lit" then .Value | unescape("\\s\\S")
    elif .Type == "SglQuoted" then if .Dollar then .Value | ansi_c else .Value end
    elif .Type == "DblQuoted" then .Parts | quoted("$`\"\\\\")
    else $expansion end;
  def word: [.Parts[] | part] | join("");
  def stdin:
    if .Op == 73 then .Word | word
    elif any(.Word.Parts[]; .Type != "Lit" or (.Value | contains("\\"))) then [.Hdoc.Parts[]?.Value] | join("")
    else .Hdoc.Parts // [] | quoted("$`\\\\") end;
  def record($stdin): (length | tostring), $stdin, .[];
  (
    .. | objects | select(.Cmd?.Type? == "CallExpr")
    | [(.Redirs // [])[] | select(.Op | IN(71, 72, 73)) | stdin] as $stdin
    | [(.Cmd.Args // [])[] | word]
    | select(length > 0)
    | record($stdin | join("\n"))
  ),
  "end"'

block() {
  printf 'agent-guard blocked this command. %s\n' "$1" >&2
  exit 2
}

# shellcheck disable=SC2016 # The backticks quote commands for the agent.
install_message='Packages are declared in the dotfiles repo, never installed by hand. Add CLI tools to home/shared/packages.nix, or to home/linux/packages.nix or home/darwin/packages.nix for one host, and macOS apps as casks in darwin/homebrew.nix. Then run `task check`. See "Declarative system management" in the dotfiles AGENTS.md.'
# shellcheck disable=SC2016
defaults_message='macOS defaults are declared under system.defaults in darwin/system.nix of the dotfiles repo. Edit that file, then run `task check`.'
# shellcheck disable=SC2016
kill_message='pkill and killall match every process whose name or command line fits, including ones you did not start. `pkill -f monitor` once ended the nixbook'"'"'s GNOME session by killing gnome-session-ctl --monitor. Kill by PID instead: `kill $!` right after you start a job, or find the PID with `pgrep -af <pattern>` and run `kill <pid>`.'
# shellcheck disable=SC2016
t3_service_message='Nix owns T3 Code'"'"'s background service, t3code.service, in home/linux/programs/t3code.nix of the dotfiles repo. `t3 up` and `t3 service install` or `uninstall` replace or remove that unit. Change the module, then run `task check`.'

has_word() {
  local word wanted
  for word in "${args[@]}"; do
    for wanted in "$@"; do
      [[ $word == "$wanted" ]] && return 0
    done
  done
  return 1
}

has_word_like() {
  local word
  for word in "${args[@]}"; do
    # shellcheck disable=SC2053 # $1 is a glob pattern.
    [[ $word == $1 ]] && return 0
  done
  return 1
}

# Returns 0 when the option takes the next word as its value. env -S splits its value
# into a command line and runs it, so that value is checked as a script.
option_takes_next_word() {
  local wrapper="$1" option="$2" next="$3" flag value i
  case "$wrapper:$option" in
    sudo:--user | sudo:--group | sudo:--host | sudo:--prompt | sudo:--chdir | sudo:--chroot | sudo:--role | sudo:--type | sudo:--command-timeout | sudo:--other-user | sudo:--close-from)
      return 0
      ;;
    env:--unset | env:--chdir) return 0 ;;
    env:--split-string) option=-S ;;
    env:--split-string=*) option="-S${option#*=}" ;;
    *:--*) return 1 ;;
  esac
  option="${option#-}"
  for ((i = 0; i < ${#option}; i += 1)); do
    flag="${option:i:1}"
    case "$wrapper:$flag" in
      sudo:[ughpCDRrtTU] | doas:[uC] | env:[uCS] | exec:a | time:[fo] | ssh:[BbcDEeFIiJLlmOoPpQRSWw])
        # In a bundle such as -uroot the rest of the word is the value.
        value="${option:i+1}"
        if [[ $wrapper:$flag == env:S ]]; then check_script "${value:-$next}" "$stdin"; fi
        if [[ -z $value ]]; then return 0; fi
        return 1
        ;;
    esac
  done
  return 1
}

# A shell runs the first word after its options as a script when -c is set, alone or in
# a bundle such as -lc. Otherwise it runs its stdin, unless a script file follows without -s.
check_shell() {
  local i=0 has_c=0 has_s=0
  while ((i < ${#args[@]})); do
    case "${args[i]}" in
      --)
        ((i += 1))
        break
        ;;
      --rcfile | --init-file) ((i += 1)) ;;
      --*) ;;
      # -o and -O take the next word, also at the end of a bundle such as -euo.
      [-+]*[oO]) ((i += 1)) ;;
      -*c*) has_c=1 ;;
      -*s*) has_s=1 ;;
      -* | +*) ;;
      *) break ;;
    esac
    ((i += 1))
  done
  if ((has_c)); then
    check_script "${args[i]-}" "$stdin"
  elif ((has_s || i == ${#args[@]})); then
    check_script "$stdin"
  fi
}

# ssh joins the words after the destination into a script for the remote shell, which
# runs ssh's stdin when there are none.
check_ssh() {
  local i=0 destination=0
  while ((i < ${#args[@]})); do
    case "${args[i]}" in
      -*) if option_takes_next_word ssh "${args[i]}" "${args[i + 1]-}"; then ((i += 1)); fi ;;
      *)
        if ((destination)); then break; fi
        destination=1
        ;;
    esac
    ((i += 1))
  done
  if ((i < ${#args[@]})); then
    check_script "${args[*]:i}" "$stdin"
  else
    check_script "$stdin"
  fi
}

check_simple_command() {
  local stdin="$1" wrapper='' i=0
  local -a words=("${@:2}") args

  while ((i < ${#words[@]})); do
    case "${words[i]}" in
      -*)
        # command -v and sudo -l only look the command up.
        case "$wrapper:${words[i]}" in
          command:-*[vV]* | sudo:-l* | sudo:--list) return 0 ;;
        esac
        if option_takes_next_word "$wrapper" "${words[i]}" "${words[i + 1]-}"; then ((i += 1)); fi
        ;;
      [A-Za-z_]*=*) ;;
      *)
        case "${words[i]##*/}" in
          sudo | doas | env | command | exec | nohup | time) wrapper="${words[i]##*/}" ;;
          *) break ;;
        esac
        ;;
    esac
    ((i += 1))
  done
  ((i < ${#words[@]})) || return 0

  local name="${words[i]##*/}"
  args=("${words[@]:i+1}")

  case "$name" in
    bash | sh | zsh | dash)
      check_shell
      ;;
    ssh)
      check_ssh
      ;;
    nix)
      if has_word profile && has_word install add upgrade remove rollback; then block "$install_message"; fi
      ;;
    nix-env)
      if has_word_like '-[iue]*' || has_word --install --upgrade --uninstall --set; then block "$install_message"; fi
      ;;
    brew)
      case "${args[0]:-}" in
        install | reinstall | upgrade | uninstall | remove | rm | tap | untap | link | unlink | pin | unpin | bundle)
          block "$install_message"
          ;;
      esac
      ;;
    npm | pnpm | bun)
      if has_word -g --global && has_word install i add update up upgrade uninstall un remove rm link ln; then
        block "$install_message"
      fi
      ;;
    yarn)
      if [[ ${args[0]:-} == global ]]; then block "$install_message"; fi
      ;;
    defaults)
      case "${args[0]:-}" in
        write | delete) block "$defaults_message" ;;
      esac
      ;;
    pkill | killall)
      block "$kill_message"
      ;;
    t3)
      case "${args[0]:-} ${args[1]:-}" in
        "up "* | "service install" | "service uninstall") block "$t3_service_message" ;;
      esac
      ;;
  esac
}

follow_up_message='Michael approves every follow-up card before it reaches Todoist. Suggest it first, with AskUserQuestion in Claude Code or one plain sentence in Codex. After he picks "Create card", rerun the command with --labels from-agent,approved. See "Work tracking" in the shared AGENTS.md.'

creates_task() {
  local quote="[\"']?" re
  re="(^|[^[:alnum:]_-])td${quote}[[:space:]]+${quote}(add|task${quote}[[:space:]]+${quote}(add|quickadd|qa))([^[:alnum:]_-]|\$)"
  [[ $command =~ $re ]]
}

carries_label() {
  local label="$1" quote="[\"']?" sep='[[:space:]]*,[[:space:]]*' flag quick_add
  flag="--labels${quote}[=[:space:]]+${quote}([^[:space:],\"']+$sep)*$label([^[:alnum:]_-]|\$)"
  quick_add="(^|[^[:alnum:]_-])@$label([^[:alnum:]_-]|\$)"
  [[ $command =~ $flag || $command =~ $quick_add ]]
}

if creates_task && carries_label from-agent && ! carries_label approved; then
  block "$follow_up_message"
fi

split_command_text_ignoring_quotes() {
  sed -E 's/&&|\|\||[;|&()`]|\$\(/\n/g' <<<"$1"
}

check_script_ignoring_quotes() {
  local segment
  local -a words
  while IFS= read -r segment; do
    read -ra words <<<"$segment"
    check_simple_command '' "${words[@]//[\"\'\\]/}"
  done < <(split_command_text_ignoring_quotes "$1")
}

check_script() {
  local json count stdin word i complete=0
  local -a words
  if ! json="$(shfmt -ln bash --to-json <<<"$1" 2>/dev/null)"; then
    check_script_ignoring_quotes "$1"
    return 0
  fi

  while IFS= read -r -d '' count; do
    if [[ $count == end ]]; then
      complete=1
      break
    fi
    IFS= read -r -d '' stdin || break
    words=()
    for ((i = 0; i < count; i += 1)); do
      IFS= read -r -d '' word || break 2
      words+=("$word")
    done
    # A command without a heredoc of its own reads the stdin of the script it is in.
    check_simple_command "${stdin:-${2-}}" "${words[@]}"
  done < <(jq --raw-output0 --arg expansion "$expansion_word" "$simple_commands_program" <<<"$json")

  ((complete)) || check_script_ignoring_quotes "$1"
}

check_script "$command"
