alias ezsh="nvim ~/.zshrc"
alias ehypr="nvim ~/.config/hypr/hyprland.conf"

alias src="source ~/.zshrc"

alias dotfiles='/usr/bin/git --git-dir="$HOME/.dotfiles/" --work-tree="$HOME"'

# tool replacements
alias ls="eza"
alias cd="z"

# zoxide init
eval "$(zoxide init zsh)"
