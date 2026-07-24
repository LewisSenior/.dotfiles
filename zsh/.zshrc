# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000
setopt autocd extendedglob nomatch notify
# Timestamp history entries and write them as they happen
setopt extendedhistory incappendhistory
bindkey -v
# End of lines configured by zsh-newuser-install
# The following lines were added by compinstall
zstyle :compinstall filename "$HOME/.zshrc"

autoload -Uz compinit
compinit
# End of lines added by compinstall

source ~/.zsh_profile

eval "$(starship init zsh)"

# Close this shell if another Alacritty window is already open
if [[ "$(ps -o comm= -p $PPID 2>/dev/null)" == "alacritty" ]]; then
  if (( $(pgrep -x alacritty | wc -l) > 1 )); then
    # Optional: message for debugging
    # echo "Another Alacritty window is already running; exiting."
    exit
  fi
fi

# Always re-enter tmux if not already in it
if [[ -z "$TMUX" ]] && [[ $- == *i* ]]; then
  while true; do
    if tmux list-sessions &>/dev/null; then
      tmux attach-session
    else
      tmux-sessionizer ~/tmp
    fi
  done
fi

alias pbcopy='wl-copy'
alias pbpaste='wl-paste'

claude() {
  if [[ -n "$CLAUDE_USE_PERSONAL" ]]; then
    local personal="${CLAUDE_PERSONAL_DIR:-$HOME/.claude-personal}"
    if [[ ! -d "$personal" ]]; then
      print -u2 "claude: $personal does not exist"
      return 1
    fi
    CLAUDE_BIN="$(whence -p claude)" \
    CLAUDE_PERSONAL="$personal" \
    CLAUDE_REAL_UID="$(id -u)" \
    CLAUDE_REAL_GID="$(id -g)" \
    unshare --user --map-root-user --mount bash -c '
      mount --bind "$CLAUDE_PERSONAL" "$HOME/.claude" || exit
      exec unshare --user \
        --map-user="$CLAUDE_REAL_UID" \
        --map-group="$CLAUDE_REAL_GID" \
        "$CLAUDE_BIN" "$@"
    ' _ "$@"
  else
    command claude "$@"
  fi
}

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# direnv. Resolve via PATH rather than a hardcoded /usr/bin/direnv, and only
# install the hook when it's actually present — an unguarded hook fires on
# every prompt and every cd, so a missing binary means an error on each one.
if (( $+commands[direnv] )); then
  _direnv_hook() {
    trap -- '' SIGINT;
    eval "$(direnv export zsh)";
    trap - SIGINT;
  }
  typeset -ag precmd_functions;
  if [[ -z "${precmd_functions[(r)_direnv_hook]+1}" ]]; then
    precmd_functions=( _direnv_hook ${precmd_functions[@]} )
  fi
  typeset -ag chpwd_functions;
  if [[ -z "${chpwd_functions[(r)_direnv_hook]+1}" ]]; then
    chpwd_functions=( _direnv_hook ${chpwd_functions[@]} )
  fi
fi
