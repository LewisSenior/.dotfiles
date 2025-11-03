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

# Created by `pipx` on 2024-06-03 21:01:44
export PATH="$PATH:/home/lewissenior/.local/bin:/opt/nvim-linux-x86_64/bin:/opt/Postman:/usr/sbin"
export HISTTIMEFORMAT="%F %T "
export PROMPT_COMMAND='history -a'
if [ -f "/home/lewissenior/.config/fabric/fabric-bootstrap.inc" ]; then . "/home/lewissenior/.config/fabric/fabric-bootstrap.inc"; fi

alias pbcopy='xclip -selection clipboard'
alias pbpaste='xclip -selection clipload -o'

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
