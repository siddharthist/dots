#!/usr/bin/env zsh

run_porcelain() {
  porcelain "$HOME/code/+personal/porcelain/conf"
  zle -Rc
  zle reset-prompt
}
zle -N run_porcelain

bindkey '^F' run_porcelain

zle_append_to_buffer() {
  BUFFER+="${1}"
  BUFFER="${BUFFER% }"
  CURSOR=$#BUFFER
  zle redisplay
}

fzf-history() {
  zle -R "" "Use 'SPC i h'"
}
zle -N fzf-history
bindkey '^R^R' fzf-history

fzf-insert-history() {
  zle_append_to_buffer "$( ([ -n "$ZSH_NAME" ] && fc -l 1 || history) | fzf +s --tac | sed -r 's/ *[0-9]*\*? *//' | sed -r 's/\\/\\\\/g')"
}
zle -N fzf-insert-history
bindkey -M vicmd ' ih' fzf-insert-history

fzf-insert-file() {
  zle_append_to_buffer "$(fd --type f . | fzf)"
}
zle -N fzf-insert-file
bindkey -M vicmd ' if' fzf-insert-file

fzf-insert-directory() {
  zle_append_to_buffer "$(fd --type d . | fzf)"
}
zle -N fzf-insert-directory
bindkey -M vicmd ' id' fzf-insert-directory

fzf-insert-show-bindings() {
  zle -R "" "d: directory" "f: file" "h: history"
}
zle -N fzf-insert-show-bindings
bindkey -M vicmd ' i' fzf-insert-show-bindings

show-bindings() {
  zle -R "" "i: insert"
}
zle -N show-bindings
bindkey -M vicmd ' ' show-bindings
