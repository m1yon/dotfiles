alias src="source ~/.zshrc"

alias dotfiles='/usr/bin/git --git-dir="$HOME/.dotfiles/" --work-tree="$HOME"'

# package management
alias cyay="yay -Yc" # cleans orphaned packages from both standard and AUR

# tool replacements
alias ls="eza"
alias cd="z"
alias task="go-task"

# tool shortcuts
alias lg="lazygit"
alias lgdf='lazygit --git-dir="$HOME/.dotfiles/" --work-tree="$HOME"'

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# pure
fpath+=($HOME/.zsh/pure)
autoload -Uz promptinit
promptinit
prompt pure

# zoxide init
eval "$(zoxide init zsh)"

# atuin init
eval "$(atuin init zsh)"

# fzf init
source <(fzf --zsh)

# add bin to path
export PATH="$HOME/.local/bin:$PATH"

# set default man pager
export MANPAGER='nvim +Man!'

# start hyprland on boot
if [ -z "$WAYLAND_DISPLAY" ] && [ "$XDG_VTNR" -eq 1 ]; then
  exec hyprland
fi

# bun completions
[ -s "/home/michael/.bun/_bun" ] && source "/home/michael/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# opencode
export PATH=/home/michael/.opencode/bin:$PATH
