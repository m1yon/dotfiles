# oh-my-zsh
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"
plugins=(git pnpm yarn)
source $ZSH/oh-my-zsh.sh

# Volta
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"

# puppeteer fix
export PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
export PUPPETEER_EXECUTABLE_PATH=which chromium

export PATH=/opt/homebrew/bin:$PATH

# Aliases
alias mfl="make frontend-logs"
alias mbl="make backend-logs"
alias di="make up && npm i && make npm-install && make down && make up"
alias mfi="npm install && make install && make npm-install"
alias pn="gco next && gl"
alias rn="gco next && gl && gco - && git rebase -"
alias ezsh="code ~/.zshrc"
alias mr="make down && make up"
alias md="make down"
alias mu="make up"
alias nuked="docker system prune -a && make install && make seed"
alias lip="ipconfig getifaddr en0"
alias gclean="git clean -xdne \".env*\""
alias gcleanf="git clean -xdfe \".env*\""
alias n10="node -v && volta install node@10.22.1&& node -v"
alias n16="node -v && volta install node@16.13.2 && node -v"
alias n18="node -v && volta install node@18.12.1 && node -v"
alias n19="node -v && volta install node@19 && node -v"
alias aic="npx aicommits"
alias ghw="gh pr view --web"
alias src="source /Users/michael/.zshrc"

# alias help
alias ghelp="open https://kapeli.com/cheat_sheets/Oh-My-Zsh_Git.docset/Contents/Resources/Documents/index"
alias phelp="open https://github.com/ntnyq/omz-plugin-pnpm"
alias yhelp="open https://github.com/ohmyzsh/ohmyzsh/blob/master/plugins/yarn/yarn.plugin.zsh"

# paths
alias ani="cd ~/Github/anify"
alias kin="cd ~/Kinsta"
alias katt="cd ~/Kinsta/kattribution"

# utils
alias nkill="pkill node"
alias nlist="pgrep node"

# kattribution
alias kattreset="katt && yarn stop && yarn prune-db"

# github links
alias kattpr="open https://github.com/kinsta/kattribution/pulls/m1yon"
alias anipr="open https://github.com/anify-app/anify/pulls/m1yon"

# pnpm
export PNPM_HOME="/Users/michael/Library/pnpm"
export PATH="$PNPM_HOME:$PATH"

# Docker Desktop
source /Users/michael/.docker/init-zsh.sh || true
