{
  programs.zsh = {
    enable = true;
    shellAliases = {
      cd = "z";
      src = "unset __HM_SESS_VARS_SOURCED && source ~/.zshenv && source ~/.zshrc";
    };
    initContent = ''
      function y() {
        local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
        command yazi "$@" --cwd-file="$tmp"
        IFS= read -r -d "" cwd < "$tmp"
        [ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd"
        rm -f -- "$tmp"
      }
    '';
  };
}
