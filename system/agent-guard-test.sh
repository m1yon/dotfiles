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

bash_event() {
  jq -cn --arg c "$1" '{tool_name: "Bash", tool_input: {command: $c}}'
}

while IFS=$'\t' read -r expected command; do
  run_case "$expected" "$(bash_event "$command")"
done <<'EOF'
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
block	pkill -f "monitor" >/dev/null 2>&1; true
block	pkill node
block	sleep 1 && sudo pkill -f vite
block	killall -9 chrome
block	t3 up
block	t3 up --lan --yes
block	t3 service install
block	~/.local/bin/t3 service uninstall
block	t3 "up"
block	t3 'service' 'install'
block	t3 service "uninstall"
block	sudo -u michael pkill -f monitor
block	sudo -Eu michael killall node
block	sudo --user michael pkill -f monitor
block	sudo -umichael pkill -f monitor
block	doas -u root killall node
block	env -u EXAMPLE pkill -f monitor
block	env FOO=1 -u EXAMPLE pkill -f monitor
block	/usr/bin/sudo pkill -f monitor
block	p\kill -f monitor
block	"pkill" -f monitor
block	npm install "-g" typescript
block	bash -lc 'pkill -f monitor'
block	sh -c "killall node"
block	zsh -ic 'sleep 1; pkill -f monitor'
block	dash -c 't3 up'
block	/bin/bash --norc -c 'brew install jq'
block	bash -o pipefail -c 'pkill -f monitor'
block	sudo bash -c 'pkill -f monitor'
block	bash -c "bash -c 'pkill -f monitor'"
block	echo $(pkill -f x)
block	echo "$(pkill -f x)"
block	echo "a $(pkill -f x) b"
block	echo `pkill -f x`
block	echo ${y:-$(pkill -f x)}
block	FOO=$(pkill -f x) true
block	cat <(pkill -f x)
block	(pkill -f x)
block	{ echo hi; pkill -f x; }
block	if true; then pkill -f x; fi
block	for pid in 1 2; do pkill -f "$pid"; done
block	true && pkill -f x || echo failed
block	echo ok | pkill -f x
block	pkill -f "$name"
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
allow	pgrep -af monitor
allow	kill "$!"
allow	git commit -m "fix: stop using pkill"
allow	t3 status
allow	t3 service status
allow	t3 thread list
allow	git commit -m "fix: guard commands; pkill -f monitor"
allow	git commit -m "docs: guard commands; t3 up --lan"
allow	git commit -m "feat: block brew install && npm install -g"
allow	grep -E "pkill|killall" system/agent-guard.sh
allow	grep -E "safe|t3 up --lan" AGENTS.md
allow	git log --grep "t3 up"
allow	echo 'a; pkill -f x'
allow	echo "pkill -f x" | cat
allow	echo "\$(pkill -f x)"
allow	echo '$(pkill -f x)'
allow	echo $'pkill -f x'
allow	sudo -u pkill ls
allow	sudo -g killall id
allow	env -u pkill ls
allow	bash -c 'echo pkill'
allow	bash -c "echo $HOME"
allow	bash -lc 'git status'
allow	bash script.sh -c 'pkill -f x'
EOF

run_case allow "$(bash_event $'cat <<\'EOF\'\npkill -f x\nEOF')"
run_case allow "$(bash_event $'cat <<EOF\npkill -f x; killall node\nEOF')"
run_case allow "$(bash_event $'git commit -F - <<EOF\nfix: stop using t3 up\nEOF')"
run_case allow "$(bash_event $'git commit -m "fix: guard\n\npkill -f monitor; t3 up"')"
run_case block "$(bash_event $'cat <<EOF\n$(pkill -f x)\nEOF')"
run_case block "$(bash_event $'cat <<\'EOF\'\npkill -f x\nEOF\npkill -f y')"
run_case block "$(bash_event $'echo hi\nsudo -u michael pkill -f monitor')"
run_case block "$(bash_event $'bash -c \'\npkill -f monitor\n\'')"
run_case block "$(bash_event $'echo "$(pkill -f x)"')"
run_case block "$(bash_event $'echo "line one\n$(pkill -f x)"')"

long_heredoc="$(
  printf 'cat <<EOF\n'
  printf 'pkill -f x; t3 up; brew install jq\n%.0s' {1..200}
  printf 'EOF\n'
)"
run_case allow "$(bash_event "$long_heredoc")"

# shfmt cannot parse zsh-only syntax, so the hook splits the text instead.
run_case block "$(bash_event 'print -l ${(k)commands}; pkill -f monitor')"
run_case block "$(bash_event 'print -l ${(k)commands}; t3 "up"')"
run_case block "$(bash_event 'print -l ${(k)commands}; p\kill -f monitor')"
run_case allow "$(bash_event 'print -l ${(k)commands}; echo hi')"

# Codex can pass the command as an argument vector.
run_case block '{"tool_name":"Bash","tool_input":{"command":["bash","-lc","brew install --cask linearmouse"]}}'
run_case block '{"tool_name":"Bash","tool_input":{"command":["bash","-lc","pkill -f monitor"]}}'
run_case block '{"tool_name":"Bash","tool_input":{"command":["bash","-c","-l","pkill -f monitor"]}}'
run_case block '{"tool_name":"Bash","tool_input":{"command":["pkill","-f","monitor"]}}'
run_case block '{"tool_name":"Bash","tool_input":{"command":["sudo","-u","michael","pkill","-f","monitor"]}}'
run_case block '{"tool_name":"Bash","tool_input":{"command":["t3","service","install"]}}'
run_case allow '{"tool_name":"Bash","tool_input":{"command":["bash","-lc","git status"]}}'
run_case allow '{"tool_name":"Bash","tool_input":{"command":["git","commit","-m","fix: guard; pkill -f monitor"]}}'
run_case allow '{"tool_name":"Bash","tool_input":{"command":["grep","-E","pkill|killall","system/agent-guard.sh"]}}'
run_case allow '{"tool_name":"apply_patch","tool_input":{}}'

if ((failures > 0)); then
  echo "$failures agent-guard case(s) failed" >&2
  exit 1
fi
echo "agent-guard: all cases passed"
