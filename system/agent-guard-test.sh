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
  run_case "$expected" "$(jq -cn --arg c "$command" '{tool_name: "Bash", tool_input: {command: $c}}')"
done <<'EOF'
block	td task add "Fix the data race in the msgraphemail tests" --project Inbox --labels from-agent
block	td task add "Remove the duplicated block" --project "Side Projects" --section Todo --labels from-agent --description "Repo m1yon/dotfiles; home/linux/gnome.nix (elif branch) | see log"
block	td task add "x" --description "a; b (c) | d" --labels from-agent
block	cd ~/GitHub/dream && td task add "Upgrade Effect" --labels=from-agent
block	td task add "x" --labels "pr-review,from-agent"
block	td add "Check the invoice month @from-agent #Inbox"
block	td task quickadd "Check the invoice month @from-agent"
block	td task qa "x @from-agent"
block	url=$(td task add "x" --labels from-agent)
allow	td task add "Fix the data race" --project Inbox --labels from-agent,approved
allow	td task add "x" --labels approved,from-agent
allow	td add "x @from-agent @approved"
allow	td task add "Build a local web frontend" --project id:abc --section "In Progress" --json
allow	td task add "feat(web): run imports in a web session" --parent id:abc
allow	td task add "x" --labels from-agents
allow	td task list --label from-agent --json
allow	td comment add id:abc --content "PR: https://github.com/m1yon/orchestrator/pull/16"
allow	grep -n "from-agent" dotfiles/agents/AGENTS.md
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
block	cd scripts/bun && sudo -E npm install -g ccstatusline
block	git pull; HOMEBREW_NO_AUTO_UPDATE=1 /opt/homebrew/bin/brew install jq
allow	brew list --cask
allow	brew info --cask linearmouse
allow	npm install
allow	npm ls -g
allow	bun install --frozen-lockfile
allow	bun add -d typescript
allow	nix profile list
allow	nix-env -q
allow	defaults read com.apple.dock autohide
allow	git commit -m "docs: say why brew install is blocked"
allow	grep -rn "npm install -g" AGENTS.md
EOF

# Codex can pass the command as an argument vector.
run_case block '{"tool_name":"Bash","tool_input":{"command":["bash","-lc","td task add \"x\" --labels from-agent"]}}'
run_case block '{"tool_name":"Bash","tool_input":{"command":["td","task","add","x","--labels","from-agent"]}}'
run_case block '{"tool_name":"Bash","tool_input":{"command":["bash","-lc","brew install --cask linearmouse"]}}'
run_case allow '{"tool_name":"apply_patch","tool_input":{}}'

if ((failures > 0)); then
  echo "$failures agent-guard case(s) failed" >&2
  exit 1
fi
echo "agent-guard: all cases passed"
