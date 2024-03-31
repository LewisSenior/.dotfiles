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
