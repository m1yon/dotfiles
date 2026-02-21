# PATH additions
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.local/scripts/bin:$PATH"
export PATH="$BUN_INSTALL/bin:$PATH"
export PATH="$HOME/.opencode/bin:$PATH"
export PATH="$HOME/.config/opencode/command/scripts/bin:$PATH"
export PATH="$HOME/go/bin:$PATH"

# Remove duplicates from PATH
typeset -U PATH
