#!/usr/bin/env bash

# Source the shell dotfiles
for file in ~/.{bash_path,bash_prompt,bash_exports,bash_aliases,bash_functions,bash_extra}; do
  [ -r "$file" ] && [ -f "$file" ] && source "$file"
done
unset file
