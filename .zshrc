# Source secrets if the file exists
if [ -f ~/.secrets ]; then
    source ~/.secrets
fi

alias src="source ~/.zshrc"

# nvm bash completion (nvm itself is loaded in .zshenv)
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

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

# set default man pager
export MANPAGER='nvim +Man!'

# start hyprland on boot
if [ -z "$WAYLAND_DISPLAY" ] && [ "$XDG_VTNR" -eq 1 ]; then
  exec hyprland
fi

# bun completions
[ -s "/home/michael/.bun/_bun" ] && source "/home/michael/.bun/_bun"
