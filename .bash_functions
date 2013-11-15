#!/usr/bin/env bash

function cd_drupal_7_site() {
  if [[ -z "$1" ]]; then
    cd $DRUPAL_ROOT/sites/
  else
    cd $DRUPAL_ROOT/sites/$1
  fi
}

function simpletest_project() {
  if [[ -z "$1" ]]; then
    echo -en "\n\033[0;32mEnter module / theme name\033[0m: "; read project
  fi
  project=${1:-$project} && site="st_${project}"

  echo -e "\n\033[0;32mSimpletest: \033[0m$project"
  site-install $site false
  pm-download $project $site
  echo -e "\n\033[0;32mOpen Safari:\033[0m"
  open -a Safari http://$site.d7
}

function site-install() {
  if [[ -z "$1" ]]; then
    dir=${PWD##*/}
    echo -en "\n\033[0;32mEnter site name\033[0m [$dir]: "; read site && site=${site:=$dir}
  else
    site=$1
  fi
  clear && cd $QUADRUPAL7_PATH/sites/$site/ && site_t="${site}_t" && db_name="dev_${site}" && repo="${site}"

  open_safari=${2:-true}
  if [ ! -d "$DRUPAL_ROOT/sites/$site" ]; then
    echo -e "\n\033[0;32mAdd multisite:\033[0m"
    cd $DRUPAL_ROOT/sites
    mkdir -p $DRUPAL_ROOT/sites/$site/{libraries,modules/{contrib,custom/$module,features},themes/$theme/templates,files/{public,private}} && chmod -R o+w $DRUPAL_ROOT/sites/$site/files
    drush si minimal --db-url=mysql://$MYSQL_USER:$MYSQL_PASS@localhost/$site --site-name=$site --sites-subdir=$site -y
    echo -e "\n\033[0;32mConfigure multisite:\033[0m"
    cd $DRUPAL_ROOT/sites/$site
    drush vset file_public_path "sites/$site/files/public"
    drush vset file_private_path "sites/$site/files/private"
    echo -e "\n\033[0;32mAdd DNS entry:\033[0m"
    sudo sed -ie "\|^127.0.0.1 ${site}.d7|d" /private/etc/hosts && echo -e "127.0.0.1 ${site}.d7" >> /private/etc/hosts
    if [ open_safari ]; then
      echo -e "\n\033[0;32mOpen Safari:\033[0m"
      open -a Safari http://$site.d7
    fi
  fi
}

function remove_multisite() {
  if [[ -z "$1" ]]; then
    dir=${PWD##*/}
    echo -en "\n\033[0;32mEnter site name\033[0m [$dir]: "; read site && site=${site:=$dir}
  else
    site=$1
  fi
  clear && cd $QUADRUPAL7_PATH/sites/$site/ && site_t="${site}_t" && db_name="dev_${site}" && repo="${site}"

  if [ -d "$DRUPAL_ROOT/sites/$site" ]; then
    echo -e "\n\033[0;32mRemove Drupal multisite:\033[0m"
    cd $DRUPAL_ROOT/sites/$site
    drush sql-drop -y && sudo rm -rf $DRUPAL_ROOT/sites/$site && cd $DRUPAL_ROOT/sites/
    echo -e "\n\033[0;32mRemove DNS entry:\033[0m"
    sudo sed -ie "\|^127.0.0.1 ${site}.d7|d" /private/etc/hosts
  fi
}

function pm-download() {
  if [[ -z "$1" ]]; then
    echo -en "\n\033[0;32mEnter project name\033[0m: "; read project
  fi
  project=${1:-$project}
  if [[ -z "$2" ]]; then
    dir=${PWD##*/}
    echo -en "\n\033[0;32mEnter site name\033[0m [$dir]: "; read site && site=${site:=$dir}
  else
    site=$2
  fi
  clear && cd $QUADRUPAL7_PATH/sites/$site/ && site_t="${site}_t" && db_name="dev_${site}" && repo="${site}"

  if [ ! -d "$DRUPAL_ROOT/sites/$site/modules/contrib/$project" ]; then
    echo -e "\n\033[0;32mDownload and enable ($project) module:\033[0m"
    cd $DRUPAL_ROOT/sites/$site && drush dl $project -y && drush en $project -y
  else
    echo -e "\n\033[0;31m $project module already available\033[0m"
    cd $DRUPAL_ROOT/sites/$site/modules/contrib/$project
  fi
}

function remove_project() {
  if [[ -z "$1" ]]; then
    dir=${PWD##*/}
    echo -en "\n\033[0;32mEnter site name\033[0m [$dir]: "; read site && site=${site:=$dir}
  else
    site=$1
  fi
  clear && cd $QUADRUPAL7_PATH/sites/$site/ && site_t="${site}_t" && db_name="dev_${site}" && repo="${site}"

  if [[ -z "$2" ]]; then
    echo -en "\n\033[0;32mEnter project name\033[0m: "; read project
  fi
  project=${2:-$project}
  if [ -d "$DRUPAL_ROOT/sites/$site/modules/contrib/$project" ]; then
    echo -e "\n\033[0;32mDisable and uninstall ($project) module:\033[0m"
    cd $DRUPAL_ROOT/sites/$site && drush dis $project -y && drush pm-uninstall $project -y
  fi
}

function generate_content() {
  drush en devel devel_generate -y
  drush generate-vocabs 10 && drush generate-users 10 && drush generate-content 200
}

function pm-list() {
  if [[ -z "$1" ]]; then
    drush pml
  else
    drush pml | grep -i $1
  fi
}
