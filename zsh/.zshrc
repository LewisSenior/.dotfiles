# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000
setopt autocd extendedglob nomatch notify
bindkey -v
# End of lines configured by zsh-newuser-install
# The following lines were added by compinstall
zstyle :compinstall filename '/home/lewissenior/.zshrc'

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

# Start tmux-sessionizer in ~/tmp if not already in tmux and only once per session
if [[ -z "$TMUX" ]] && [[ $- == *i* ]]; then
  tmux-sessionizer ~/tmp
fi

# Created by `pipx` on 2024-06-03 21:01:44

#export PATH="$PATH:/home/lewissenior/.local/bin:/opt/nvim-linux-x86_64/bin:/opt/Postman:/usr/sbin"
export HISTTIMEFORMAT="%F %T "
export PROMPT_COMMAND='history -a'
if [ -f "/home/lewissenior/.config/fabric/fabric-bootstrap.inc" ]; then . "/home/lewissenior/.config/fabric/fabric-bootstrap.inc"; fi

alias pbcopy='xclip -selection clipboard'
alias pbpaste='xclip -selection clipload -o'

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# opencode
export PATH=/home/lewis/.opencode/bin:$PATH
eval 
_direnv_hook() {
  trap -- '' SIGINT;
  eval "$("/usr/bin/direnv" export zsh)";
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
