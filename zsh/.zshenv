# PATH additions
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.local/scripts/bin:$PATH"
export PATH="$BUN_INSTALL/bin:$PATH"
export PATH="$HOME/.opencode/bin:$PATH"
export PATH="$HOME/.config/opencode/command/scripts/bin:$PATH"
export PATH="$HOME/go/bin:$PATH"

# Remove duplicates from PATH
typeset -U PATH

# ENV variables
export EDITOR="nvim"
export BUN_INSTALL="$HOME/.bun"
export AWS_SDK_LOAD_CONFIG=1
export OPENCODE_EXPERIMENTAL_PLAN_MODE=1
export AGENT_BROWSER_EXECUTABLE_PATH="/usr/bin/google-chrome-stable"
