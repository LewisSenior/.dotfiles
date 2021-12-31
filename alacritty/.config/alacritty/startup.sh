#!/bin/bash

TMUXTEST=$(tmux list-sessions 2>&1 | grep 'no server')
TMUXSESH=$(tmux list-sessions)

if [ "$TMUXTEST" ]
then
	tmux
else
	echo "SERVER DETECTEED"
	
fi
