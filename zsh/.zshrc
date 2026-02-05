# Source secrets if the file exists
if [ -f ~/.secrets ]; then
    source ~/.secrets
fi

alias src="source ~/.zshrc && source ~/.zshenv"

# nvm bash completion (nvm itself is loaded in .zshenv)
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# pure
fpath+=($HOME/.zsh/pure)
autoload -Uz promptinit
promptinit
prompt pure

# zoxide init
eval "$(zoxide init zsh)"
alias cd="z"

# atuin init
eval "$(atuin init zsh)"

# fzf init
source <(fzf --zsh)

# set default man pager
export MANPAGER='nvim +Man!'

# bun completions
[ -s "/home/michael/.bun/_bun" ] && source "/home/michael/.bun/_bun"

# completion styles
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# uwsm auto-start
if uwsm check may-start; then
    exec uwsm start hyprland.desktop
fi

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Aliases
alias ls="eza"
alias lg="lazygit"
alias cyay="yay -Yc"

. "$HOME/.local/share/../bin/env"
