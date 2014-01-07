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
alias dl=core_download
alias up=core_update
alias si=site_install
alias sd=site_delete
alias cc=_cache_clear
alias sqls=sql_sync
alias unsuck="drush unsuck"
alias offline="drush offline"
alias online="drush online"
alias fl="drush fl"
alias fu="drush fu -y $1"
alias updb="drush updb -y"

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

# Alias the drupal version keys.
for version_key in "${DRUPAL_VERSION_KEY[@]}"; do
  alias $version_key="cd $DRUPAL_BASE_FOLDER/$version_key"
done
