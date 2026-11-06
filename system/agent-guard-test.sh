# Usage: agent-guard-test.sh <path to agent-guard>
# Feeds each case to the hook the way Claude Code and Codex do, and checks that
# it blocks (exit 2) or allows (exit 0) the command.

guard="$1"
failures=0

run_case() {
  local expected="$1" event="$2" status=0
  "$guard" <<<"$event" 2>/dev/null || status=$?
  case "$expected:$status" in
    block:2 | allow:0) ;;
    *)
      echo "FAIL: expected $expected, got exit $status: $event" >&2
      failures=$((failures + 1))
      ;;
  esac
}

while IFS=$'\t' read -r expected command; do
  [[ -z $expected || $expected == \#* ]] && continue
  run_case "$expected" "$(jq -cn --arg c "$command" '{tool_name: "Bash", tool_input: {command: $c}}')"
done <<'EOF'
# Switch commands an agent copies from Taskfile.yml.
block	sudo darwin-rebuild switch --flake path:/Users/michael/GitHub/dotfiles#macbook
block	sudo nix --extra-experimental-features 'nix-command flakes' run github:nix-darwin/nix-darwin/nix-darwin-26.05#darwin-rebuild -- switch --flake path:/Users/michael/GitHub/dotfiles#macbook
block	nixos-rebuild switch --flake path:/home/michael/GitHub/dotfiles#nixbook --sudo
block	nix run home-manager -- switch --flake /home/michael/GitHub/dotfiles#michael@nixbook
block	task rebuild-home
# The same commands behind wrappers and lists.
block	cd ~/GitHub/dotfiles && sudo -E nixos-rebuild switch --flake .#nixbook
block	git pull; NIX_SUDOOPTS=-A /run/current-system/sw/bin/nixos-rebuild boot --flake .#nixbook
block	home-manager switch --flake .#michael@macbook
block	sudo /nix/var/nix/profiles/system/bin/switch-to-configuration switch
# The supported entry points and read-only commands.
allow	SUDO_PASSWORD_FILE=/tmp/sudo task rebuild
allow	task check
allow	nixos-rebuild build --flake .#nixbook
allow	nix eval --raw .#darwinConfigurations.macbook.system.drvPath
allow	nix run nixpkgs#hello
allow	home-manager --help
allow	git commit -m "docs: say when to run darwin-rebuild switch"
allow	grep -rn "nixos-rebuild switch" AGENTS.md
# Imperative installs of tools the repo later had to declare in Nix, and the
# examples AGENTS.md forbids by name.
block	brew install --cask linearmouse
block	brew tap charmbracelet/tap
block	brew upgrade
block	npm install -g @anthropic-ai/claude-code
block	npm i -g ccstatusline
block	bun add -g ccstatusline
block	pnpm add --global typescript
block	yarn global add typescript
block	nix profile install nixpkgs#jq
block	nix --extra-experimental-features 'nix-command flakes' profile add nixpkgs#jq
block	nix-env -iA nixpkgs.jq
block	defaults write com.apple.dock autohide -bool true
# Project-local installs and read-only queries.
allow	brew list --cask
allow	brew info --cask linearmouse
allow	npm install
allow	npm ls -g
allow	bun install --frozen-lockfile
allow	bun add -d typescript
allow	nix profile list
allow	nix-env -q
allow	defaults read com.apple.dock autohide
EOF

# Codex can pass the command as an argument vector.
run_case block '{"tool_name":"Bash","tool_input":{"command":["bash","-lc","darwin-rebuild switch --flake .#macbook"]}}'
run_case allow '{"tool_name":"apply_patch","tool_input":{}}'

if ((failures > 0)); then
  echo "$failures agent-guard case(s) failed" >&2
  exit 1
fi
echo "agent-guard: all cases passed"
