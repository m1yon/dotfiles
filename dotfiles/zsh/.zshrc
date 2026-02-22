# Source secrets if the file exists
if [ -f ~/.secrets ]; then
    source ~/.secrets
fi

# set default man pager
export MANPAGER='nvim +Man!'

# uwsm auto-start
if uwsm check may-start; then
  exec uwsm start hyprland.desktop
fi
