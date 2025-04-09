#!/bin/bash

DIR="${1:-$PWD}"
SESSION_NAME=$(basename "$DIR")

# Launch main window with vim inside zsh
tmux -u new-session -d -s "$SESSION_NAME" -n "main" "zsh -ic 'cd \"$DIR\" && exec vim .'"

# Launch other windows running zsh in the same dir
tmux new-window -t "$SESSION_NAME:" -n "ter 1" -c "$DIR" "zsh"
tmux new-window -t "$SESSION_NAME:" -n "ter 2" -c "$DIR" "zsh"
tmux new-window -t "$SESSION_NAME:" -n "ter 3" -c "$DIR" "zsh"

# Attach using -u for UTF-8 passthrough
tmux -u attach-session -t "$SESSION_NAME"
