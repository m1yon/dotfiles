# PreToolUse hook for Claude Code and Codex. It reads the hook event on stdin and
# exits 2 to block a Bash call; both harnesses show stderr to the agent.

data_commands='git gh grep egrep fgrep rg echo printf cat tee td'

# Codex can pass an argument vector, such as ["bash", "-lc", "<script>"].
command="$(jq -r --arg data "$data_commands" '
  def shell_c_script:
    if length >= 3 and (.[-2] | test("^-l?c$")) and (.[0] | tostring | split("/")[-1] | IN($data | split(" ")[]) | not)
    then .[-1] else empty end;
  .tool_input.command // ""
  | if type != "array" then . else first(shell_c_script, (map(tostring | @sh) | join(" "))) end')"

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
  def region($kind): [.Pos.Offset, .End.Offset, $kind];
  def data_command: .Cmd.Type? == "CallExpr" and (.Cmd.Args[0] | if . then word | split("/")[-1] | IN($data | split(" ")[]) else false end);
  def blanked($kinds; $regions):
    def close($to):
      until((.open | length) == 0 or .open[-1][0] > $to;
        .open[-1] as [$end, $blank]
        | (if $blank then .out += [[.at, $end]] else . end)
        | .at = $end | .open |= .[:-1]);
    reduce ($regions[] | select(.[2] | IN("keep", $kinds[]))) as [$start, $end, $kind] ({open: [], at: 0, out: []};
      close($start)
      | (if (.open | length) > 0 and .open[-1][1] then .out += [[.at, $start]] else . end)
      | .at = $start
      | .open += [[$end, $kind != "keep"]])
    | close(infinite) | .out | map(select(.[0] < .[1]) | join(" ")) | join("\n");
  (
    [
      (.. | objects | select(.Type? | IN("CmdSubst", "ProcSubst")) | region("keep")),
      (
        .. | objects | select(has("Cmd"))
        | data_command as $data_command
        | (if $data_command then .Cmd.Args[1:][] | region("data") else empty end),
          ((.Redirs // [])[] | select(.Op | IN(71, 72, 73)) | if .Op == 73 then .Word else .Hdoc end | values
            | region(if $data_command then "data" else "heredoc" end))
      )
    ]
    | sort_by(.[0], -.[1], .[2] == "keep")
  ) as $regions
  | blanked(["data"]; $regions),
  blanked(["data", "heredoc"]; $regions),
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
      sudo:[ughpCDRrtTU] | doas:[uC] | env:[uCPS] | exec:a | time:[fo] | ssh:[BbcDEeFIiJLlmOoPpQRSWw])
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
  local i=0 has_c=0 has_s=0 takes_value
  while ((i < ${#args[@]})); do
    case "${args[i]}" in
      --)
        ((i += 1))
        break
        ;;
      --rcfile | --init-file | --emulate) ((i += 1)) ;;
      --*) ;;
      -* | +*)
        if [[ ${args[i]} == -*c* ]]; then has_c=1; fi
        if [[ ${args[i]} == -*s* ]]; then has_s=1; fi
        # Each o or O in a bundle such as -ceuo takes one of the next words.
        takes_value="${args[i]//[!oO]/}"
        i=$((i + ${#takes_value}))
        ;;
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
  local i=0 j destination=0 flags value lowered rest prints_config=0 remote_command
  local -a remote_commands=()
  while ((i < ${#args[@]})); do
    case "${args[i]}" in
      -*)
        flags="${args[i]#-}" value='' rest=$((i + 1))
        for ((j = 0; j < ${#flags}; j += 1)); do
          case "${flags:j:1}" in
            o)
              value="${flags:j+1}"
              if [[ -z $value ]]; then value="${args[i + 1]-}" rest=$((i + 2)); fi
              break
              ;;
            [BbcDEeFIiJLlmOPpQRSWw]) break ;;
          esac
        done
        # OpenSSH trims and lowercases the keyword, so any -o value that names RemoteCommand
        # counts, and what follows the keyword is the remote command.
        lowered="${value,,}"
        if [[ $lowered == *remotecommand* && $remote_command_words != skip ]]; then
          lowered="${lowered%%remotecommand*}"
          value="${value:${#lowered}+13}"
          value="${value#"${value%%[![:space:]=\"\']*}"}"
          # Splitting with quotes ignored cuts the value apart, so the words after it may belong to it.
          if [[ $remote_command_words == split ]]; then value+=" ${args[*]:rest}"; fi
          remote_commands+=("$value")
        fi
        # ssh -G prints its configuration and runs nothing.
        if [[ ${args[i]} =~ ^-[46AaCfGgKkMNnqsTtVvXxYy]*G ]]; then prints_config=1; fi
        if option_takes_next_word ssh "${args[i]}" "${args[i + 1]-}"; then ((i += 1)); fi
        ;;
      *)
        if ((destination)); then break; fi
        destination=1
        ;;
    esac
    ((i += 1))
  done
  if ((prints_config)); then return 0; fi
  for remote_command in "${remote_commands[@]}"; do
    check_script "$remote_command" "$stdin"
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
    trap)
      if [[ ${args[0]-} == -* ]]; then args=("${args[@]:1}"); fi
      check_script "${args[0]-}" "$stdin"
      ;;
    pkill | killall)
      block "$kill_message"
      ;;
    t3)
      local -a subcommand=()
      local j
      for ((j = 0; j < ${#args[@]}; j += 1)); do
        case "${args[j]}" in
          --log-level | --completions | --base-dir) ((j += 1)) ;;
          -*) ;;
          *) subcommand+=("${args[j]}") ;;
        esac
      done
      case "${subcommand[0]:-} ${subcommand[1]:-}" in
        "up "* | "service install" | "service uninstall") block "$t3_service_message" ;;
      esac
      ;;
    *)
      check_package_rules "$name"
      ;;
  esac
}

check_package_rules() {
  local verb
  case "$1" in
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
      if { has_word -g --global --global=true --location=global || [[ " ${args[*]} " == *" --location global "* ]]; } &&
        has_word install i add update up upgrade uninstall un remove rm link ln; then
        block "$install_message"
      fi
      ;;
    yarn)
      if [[ ${args[0]:-} == global ]]; then block "$install_message"; fi
      ;;
    defaults)
      case "${args[0]:-}" in
        -currentHost) verb="${args[1]:-}" ;;
        -host) verb="${args[2]:-}" ;;
        *) verb="${args[0]:-}" ;;
      esac
      case "$verb" in
        write | delete) block "$defaults_message" ;;
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

# Sets the array named $1 to the pieces of $2 between shell operators, cut even inside
# quotes. read takes one pass over the text, where a pattern substitution takes time
# quadratic in the number of operators.
split_command_text_ignoring_quotes() {
  local IFS=$';|&()`\n'
  read -r -d '' -a "$1" <<<"$2" || true
}

check_package_rules_skipping_wrappers_and_options() {
  local i=0
  local -a words=("$@") args
  while ((i < ${#words[@]})); do
    case "${words[i]}" in
      sudo | doas | env | command | exec | nohup | time | -* | [A-Za-z_]*=*) ((i += 1)) ;;
      *) break ;;
    esac
  done
  ((i < ${#words[@]})) || return 0
  args=("${words[@]:i+1}")
  check_package_rules "${words[i]##*/}"
}

check_script_ignoring_quotes() {
  local text_with_heredocs="$1" text_without_heredocs="$2" segment
  local -a segments words
  split_command_text_ignoring_quotes segments "$text_with_heredocs"
  for segment in "${segments[@]}"; do
    read_words "$segment"
    check_package_rules_skipping_wrappers_and_options "${words[@]//[\"\'\\]/}"
  done
  split_command_text_ignoring_quotes segments "$text_without_heredocs"
  for segment in "${segments[@]}"; do
    read_words "$segment"
    check_simple_command '' "${words[@]//[\"\'\\]/}"
  done
}

# Sets words to the words of $1. A piece that ends in $ was cut at $(, so that $ is
# dropped. ${1%\$} would take time quadratic in the length of $1.
read_words() {
  if [[ ${1: -1} == '$' ]]; then
    read -ra words <<<"${1:0:-1}"
  else
    read -ra words <<<"$1"
  fi
}

# Sets the variable named $1 to $2 with each byte range in $3 replaced by spaces. It reads
# $2 once as a stream, since bash copies a whole string to take any part of it. shfmt
# counts offsets in bytes, hence LC_ALL=C.
blank() {
  local LC_ALL=C start end at=0 piece
  local -a pieces=()
  {
    while read -r start end && [[ -n $start ]]; do
      if ((start > at)); then
        read -r -N "$((start - at))" piece <&3
        pieces+=("$piece")
      fi
      read -r -N "$((end - start))" piece <&3
      printf -v piece '%*s' "$((end - start))" ''
      pieces+=("$piece")
      at=$end
    done <<<"$3"
    IFS= read -r -d '' piece <&3 || true
    pieces+=("$piece")
  } 3<<<"$2"
  printf -v "$1" '%s' "${pieces[@]}"
}

check_script() {
  # ssh reads RemoteCommand from parsed words, skips it when the splitter repeats a parsed
  # script, and reads it from split words when the parser failed.
  local json data_ranges='' heredoc_ranges='' count stdin word i complete=0 text_with_heredocs text_without_heredocs remote_command_words='parsed'
  local -a words
  if json="$(shfmt -ln bash --to-json <<<"$1" 2>/dev/null)"; then
    {
      IFS= read -r -d '' data_ranges || true
      IFS= read -r -d '' heredoc_ranges || true
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
      done
    } < <(jq --raw-output0 --arg expansion "$expansion_word" --arg data "$data_commands" "$simple_commands_program" <<<"$json")
  fi

  if ((complete)); then
    blank text_with_heredocs "$1" "$data_ranges"
    blank text_without_heredocs "$1" "$heredoc_ranges"
    remote_command_words='skip'
    check_script_ignoring_quotes "$text_with_heredocs" "$text_without_heredocs"
  else
    remote_command_words='split'
    check_script_ignoring_quotes "$1" "$1"
  fi
}

check_script "$command"
