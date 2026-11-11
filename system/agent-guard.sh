# PreToolUse hook for Claude Code and Codex. It reads the hook event on stdin and
# exits 2 to block a Bash call; both harnesses show stderr to the agent.
#
# shfmt parses the command into a syntax tree. Every simple command in it, however
# deeply nested, becomes an argv of literal words: quotes removed, backslash escapes
# resolved, and each expansion replaced by expansion_word. The rules read that argv.
# Input shfmt cannot parse, such as zsh-only syntax, falls back to splitting the text.

# Codex can pass an argument vector, such as ["bash", "-lc", "<script>"].
command="$(jq -r '
  .tool_input.command // ""
  | if type != "array" then .
    elif length >= 3 and (.[-2] | test("^-l?c$")) then .[-1]
    else map(tostring | @sh) | join(" ")
    end')"

expansion_word='__EXPANSION__'

# shellcheck disable=SC2016 # These are jq variables, not shell expansions.
simple_commands_program='
  def part:
    if .Type == "Lit" then .Value | gsub("\\\\(?<c>[\\s\\S])"; .c)
    elif .Type == "SglQuoted" then
      if .Dollar and (.Value | contains("\\")) then $expansion else .Value end
    elif .Type == "DblQuoted" then
      [.Parts[] | if .Type == "Lit" then .Value | gsub("\\\\(?<c>[$`\"\\\\])"; .c) else $expansion end] | join("")
    else $expansion end;
  def word: [.Parts[] | part] | join("");
  (
    .. | objects | select(.Type? == "CallExpr")
    | [(.Args // [])[] | word]
    | select(length > 0)
    | (length | tostring), "\u0000", (.[] | ., "\u0000")
  ),
  "end", "\u0000"'

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

option_takes_next_word() {
  local wrapper="$1" option="$2" flag i
  case "$wrapper:$option" in
    sudo:--user | sudo:--group | sudo:--host | sudo:--prompt | sudo:--chdir | sudo:--chroot | sudo:--role | sudo:--type | sudo:--command-timeout | sudo:--other-user | sudo:--close-from)
      return 0
      ;;
    env:--unset | env:--chdir) return 0 ;;
    *:--*) return 1 ;;
  esac
  option="${option#-}"
  for ((i = 0; i < ${#option}; i += 1)); do
    flag="${option:i:1}"
    case "$wrapper:$flag" in
      sudo:[ughpCDRrtTU] | doas:[uC] | env:[uC])
        # In a bundle such as -uroot the rest of the word is the value.
        if ((i == ${#option} - 1)); then return 0; fi
        return 1
        ;;
    esac
  done
  return 1
}

# A shell run with -c, alone or in a bundle such as -lc, takes the first word after
# its options as a script.
check_shell_c_script() {
  local i=0 has_c=0
  while ((i < ${#args[@]})); do
    case "${args[i]}" in
      --)
        ((i += 1))
        break
        ;;
      --rcfile | --init-file | -o | +o | -O | +O) ((i += 1)) ;;
      --*) ;;
      -*c*) has_c=1 ;;
      -* | +*) ;;
      *) break ;;
    esac
    ((i += 1))
  done
  if ((has_c)); then check_script "${args[i]-}"; fi
}

check_simple_command() {
  local -a words=("$@")

  local wrapper='' i=0
  while ((i < ${#words[@]})); do
    case "${words[i]}" in
      -*)
        if option_takes_next_word "$wrapper" "${words[i]}"; then ((i += 1)); fi
        ;;
      [A-Za-z_]*=*) ;;
      *)
        case "${words[i]##*/}" in
          sudo | doas | env) wrapper="${words[i]##*/}" ;;
          command | exec | nohup | time) wrapper='' ;;
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
      check_shell_c_script
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

split_command_text_ignoring_quotes() {
  sed -E 's/&&|\|\||[;|&()`]|\$\(/\n/g' <<<"$1"
}

check_script_ignoring_quotes() {
  local segment
  local -a words
  while IFS= read -r segment; do
    read -ra words <<<"$segment"
    check_simple_command "${words[@]//[\"\'\\]/}"
  done < <(split_command_text_ignoring_quotes "$1")
}

check_script() {
  local json count word i complete=0
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
    words=()
    for ((i = 0; i < count; i += 1)); do
      IFS= read -r -d '' word || break 2
      words+=("$word")
    done
    check_simple_command "${words[@]}"
  done < <(jq -j --arg expansion "$expansion_word" "$simple_commands_program" <<<"$json")

  ((complete)) || check_script_ignoring_quotes "$1"
}

args=()
check_script "$command"
