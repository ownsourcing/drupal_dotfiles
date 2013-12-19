#!/bin/bash

# Easier navigation
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."

# Shortcuts
alias g="git"
alias h="history"
alias j="jobs"
alias v="vim"
alias o="open"
alias oo="open ."

# Drupal shortcuts
alias dl=core-download
alias up=core-update
alias si=site-install
alias cc=cache-clear
alias sqls=sql-sync

# # Project shortcuts
# alias ap=add_project
# alias rp=remove_project
# alias tp=simpletest_project

# alias gc=generate_content
# alias rs=remove_multisite
alias pml=pm-list
# alias dl=pm-download
# alias cc="drush cc all"
# alias si=site-install

for version_key in "${DRUPAL_VERSION_KEY[@]}"; do
  alias $version_key="cd $DRUPAL_BASE_FOLDER/$version_key"
done
