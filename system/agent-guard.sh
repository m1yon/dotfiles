# PreToolUse hook for Claude Code and Codex. It reads the hook event on stdin and
# exits 2 to block a Bash call; both harnesses show stderr to the agent.

# Codex can pass an argument vector, such as ["bash", "-lc", "<script>"].
command="$(jq -r '
  .tool_input.command // ""
  | if type != "array" then .
    elif length >= 3 and (.[-2] | test("^-l?c$")) then .[-1]
    else join(" ")
    end')"

block() {
  printf 'agent-guard blocked this command. %s\n' "$1" >&2
  exit 2
}

# shellcheck disable=SC2016 # The backticks quote commands for the agent.
switch_message='Only `task rebuild` may switch a system. On nixbook, run `SUDO_PASSWORD_FILE=<file> task rebuild` after `task check` passes. On the Mac, ask Michael to run `task rebuild`. See "Rebuild permissions" in the dotfiles AGENTS.md.'
# shellcheck disable=SC2016
install_message='Packages are declared in the dotfiles repo, never installed by hand. Add CLI tools to home/shared/packages.nix, or to home/linux/packages.nix or home/darwin/packages.nix for one host, and macOS apps as casks in darwin/homebrew.nix. Then run `task check`. See "Declarative system management" in the dotfiles AGENTS.md.'
# shellcheck disable=SC2016
defaults_message='macOS defaults are declared under system.defaults in darwin/system.nix of the dotfiles repo. Edit that file, then run `task check`.'

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

check_simple_command() {
  local -a words
  read -ra words <<<"$1"

  # Skip leading environment assignments and wrappers such as sudo, with their flags.
  local i=0
  while ((i < ${#words[@]})); do
    case "${words[i]}" in
      sudo | doas | env | command | exec | nohup | time | -*) ((i += 1)) ;;
      [A-Za-z_]*=*) ((i += 1)) ;;
      *) break ;;
    esac
  done
  ((i < ${#words[@]})) || return 0

  local name="${words[i]##*/}"
  name="${name//[\"\']/}"
  args=("${words[@]:i+1}")

  case "$name" in
    nixos-rebuild | nixos-rebuild-ng | darwin-rebuild)
      if has_word switch boot test activate; then block "$switch_message"; fi
      ;;
    home-manager)
      if has_word switch; then block "$switch_message"; fi
      ;;
    switch-to-configuration)
      block "$switch_message"
      ;;
    task)
      if has_word rebuild-home; then block "$switch_message"; fi
      ;;
    nix)
      if has_word run && has_word switch activate boot &&
        { has_word_like '*darwin-rebuild*' || has_word_like '*nixos-rebuild*' || has_word_like '*home-manager*'; }; then
        block "$switch_message"
      fi
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
  esac
}

# Check each simple command in a pipeline or list on its own. Quotes are not
# parsed, so a quoted separator can split a command early.
args=()
while IFS= read -r segment; do
  check_simple_command "$segment"
done < <(sed -E 's/&&|\|\||[;|&()`]|\$\(/\n/g' <<<"$command")
