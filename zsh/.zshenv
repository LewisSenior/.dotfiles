. "$HOME/.cargo/env"

export SSH_AUTH_SOCK=~/.1password/agent.sock

# Canonical PATH for all zsh instances (login, interactive, scripts).
# typeset -U dedupes against whatever the session already provides.
# ~/.profile mirrors the system extras for the graphical login session.
typeset -U path
path=(
  "$HOME/bin"
  "$HOME/.local/bin"
  "$HOME/.local/bin/scripts"
  "$HOME/.local/bin/odin"
  "$HOME/.opencode/bin"
  $path
  /opt/nvim-linux-x86_64/bin
  /opt/Postman
  /usr/pgadmin4/bin
  /usr/sbin
  /snap/bin
)
