# Aliases (available in all zsh sessions, including non-interactive)
alias task="go-task"
alias ls="eza"
alias cd="z"
alias lg="lazygit"
alias lgdf='lazygit --git-dir="$HOME/.dotfiles/" --work-tree="$HOME"'
alias dotfiles='/usr/bin/git --git-dir="$HOME/.dotfiles/" --work-tree="$HOME"'
alias cyay="yay -Yc"

# PATH additions
export PATH="$HOME/.local/bin:$PATH"
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
export PATH="$HOME/.opencode/bin:$PATH"

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
