#!/bin/bash

DOT_REPO="$(dirname "${BASH_SOURCE}")"

cd $DOT_REPO
git pull origin master

# Copies all the files from the repo to the HOME folder.
function doIt() {
  rsync --exclude ".git/" --exclude ".DS_Store" --exclude "bootstrap.sh" --exclude "readme.md" -av --no-perms . ~

  source ~/.bash_profile
}

if [ "$1" == "--force" -o "$1" == "-f" ]; then
  doIt
else
  read -p "This may overwrite existing files in your home directory. Are you sure? (y/n) " -n 1
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    doIt
  fi
fi
unset doIt
