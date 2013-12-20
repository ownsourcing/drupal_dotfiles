#!/bin/bash

DOT_REPO="$PWD"

cd $DOT_REPO
git pull origin master

function install_dotfiles() {
  if [ ! -f "$HOME/.bash_profile" ]; then echo -e "#!/bin/bash" > $HOME/.bash_profile; fi
  if [ ! -f "$HOME/.bashrc" ]; then echo -e "#!/bin/bash" > $HOME/.bashrc; fi
  if [ ! -f "$HOME/.bash_extra" ]; then echo -e "#!/bin/bash\n\n# Drupal installation settings.\nDRUPAL_VERSION_DEFAULT=7\nDRUPAL_VERSION_KEY[6]='d6'\nDRUPAL_VERSION_KEY[7]='d7'\nDRUPAL_VERSION_KEY[8]='d8'\nDRUPAL_BASE_FOLDER=\$HOME/Sites\n\n# Drupal admin settings.\nDRUPAL_ADMIN_USER='admin'\nDRUPAL_ADMIN_EMAIL='admin@domain.nl'\nDRUPAL_ADMIN_PASS='admin_pass'\n\n# MYSQL settings.\nMYSQL_USER='user_name'\nMYSQL_PASS='user_pass'" > $HOME/.bash_extra; fi
  if [ ! -f "$HOME/.drush/drush_locale_sync" ]; then git clone --branch master http://git.drupal.org/sandbox/johnnyvdlaar/1872144.git $HOME/.drush/drush_locale_sync; fi
  if [ ! -f "$HOME/.drush/drush_debug" ]; then git clone git@github.com:willembressers/drush_debug.git $HOME/.drush/drush_debug; fi

  if [ ! -f "$HOME/.gitconfig" ]; then
    git config --global core.excludesfile '$HOME/.gitignore'
    git config --global core.attributesfile '$HOME/.gitattributes'
    git config --global core.whitespace 'space-before-tab,indent-with-non-tab,trailing-space'
    git config --global core.autocrlf 'input'

    git config --global color.diff 'auto'
    git config --global color.status 'auto'
    git config --global color.branch 'auto'
    git config --global color.ui 'true'

    git config --global alias.out 'log master --oneline --pretty=format:"%C(yellow)%h %C(red)%ad %C(green)%an%C(green) %Creset%s" --date=short --no-merges --max-count=25'
  fi

  if [[ ! ( -f "$HOME/.bash_path" && -f "$HOME/.bash_exports" && -f "$HOME/.bash_aliases" && -f "$HOME/.bash_functions" ) ]]; then
    echo -e "/n source $HOME/.bash_profile" >> $HOME/.bashrc
    echo -e "\n\n# Source the dotfiles.\n source $HOME/.bash_path\n source $HOME/.bash_exports\n source $HOME/.bash_aliases\n source $HOME/.bash_functions\n source $HOME/.bash_extra" >> $HOME/.bash_profile
  fi
}

# Copies all the files from the repo to the HOME folder.
function update_dotfiles() {

  if [ ! -f "$HOME/.bash_extra" ]; then
    install_dotfiles
  fi

  files=(.bash_path .bash_exports .bash_aliases .bash_functions)
  for file in ${files[*]}; do
    cp $DOT_REPO/$file $HOME/$file
    source $HOME/$file
  done

  cp $DOT_REPO/.vimrc $HOME/.vimrc
}

if [ "$1" == "--force" -o "$1" == "-f" ]; then
  update_dotfiles
else
  read -p "This may overwrite existing files in your home directory. Are you sure? (y/n) " -n 1
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    update_dotfiles
  fi
fi
