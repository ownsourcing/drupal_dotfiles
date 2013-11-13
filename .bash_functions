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

  add_multisite $site false
  add_project $site $project

  echo -e "\n\033[0;32mOpen Safari:\033[0m"
  open -a Safari http://$site.d7
}

function add_multisite() {
  if [[ -z "$1" ]]; then
    echo -en "\n\033[0;32mEnter site name\033[0m: "; read site
  fi
  site=${1:-$site}
  open_safari=${2:-true}
  if [ ! -d "$DRUPAL_ROOT/sites/$site" ]; then
    echo -e "\n\033[0;32mAdd multisite:\033[0m"
    cd $DRUPAL_ROOT/sites
    mkdir -p $DRUPAL_ROOT/sites/$site/{libraries,modules/{contrib,custom/$module,features},themes/$theme/templates,files/{public,private}} && chmod -R o+w $DRUPAL_ROOT/sites/$site/files
    drush si standard --db-url=mysql://$MYSQL_USER:$MYSQL_PASS@localhost/$site --site-name=$site --site-mail=root+$site+$EMAIL --account-mail=$site+$EMAIL --account-name=$MYSQL_USER --account-pass=$MYSQL_PASS --sites-subdir=$site -y

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
    echo -en "\n\033[0;32mEnter site name\033[0m: "; read site
  fi
  site=${1:-$site}
  if [ -d "$DRUPAL_ROOT/sites/$site" ]; then
    echo -e "\n\033[0;32mRemove Drupal multisite:\033[0m"
    cd $DRUPAL_ROOT/sites/$site
    drush sql-drop -y && sudo rm -rf $DRUPAL_ROOT/sites/$site && cd $DRUPAL_ROOT/sites/

    echo -e "\n\033[0;32mRemove DNS entry:\033[0m"
    sudo sed -ie "\|^127.0.0.1 ${site}.d7|d" /private/etc/hosts
  fi
}

function add_project() {
  if [[ -z "$1" ]]; then
    echo -en "\n\033[0;32mEnter site name\033[0m: "; read site
  fi
  site=${1:-$site}
  if [[ -z "$2" ]]; then
    echo -en "\n\033[0;32mEnter project name\033[0m: "; read project
  fi
  project=${2:-$project}
  if [ ! -d "$DRUPAL_ROOT/sites/$site/modules/contrib/$project" ]; then
    echo -e "\n\033[0;32mDownload and enable ($project) module:\033[0m"
    cd $DRUPAL_ROOT/sites/$site && drush dl $project -y && drush en $project -y
  fi
}

function remove_project() {
  if [[ -z "$1" ]]; then
    echo -en "\n\033[0;32mEnter site name\033[0m: "; read site
  fi
  site=${1:-$site}
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

# # Syncs the test database into local.
# function sync_drupal_database () {
#   if [[ -z "$1" ]]; then
#     echo -e "\033[1;31mError: provide drush alias.\033[0m"
#   else
#     cd $DRUPAL_ROOT/sites/$1

#     echo -e "\n\033[0;32mSyncing the ($1) database\033[0m"
#     drush sql-sync @$1_t @$1 -y

#     echo -e "\n\033[0;32mDrush action\033[0m"
#     drush wd-del all -y && drush fra -y && drush updb -y && drush cc all

#     echo -e "\n\033[0;32mAlter the configuration\033[0m"
#     drush vset site_mail "$1+site+$EMAIL" && drush sqlq "update users set mail='$1+root+$EMAIL' where users.uid =1"

#     echo -e "\n\033[0;32mEnable developer modules\033[0m"
#     drush en devel devel_generate potx coder update statistics simpletest search_krumo -y

#     echo -e "\n\033[0;32mGenerate dummy content\033[0m"
#     drush generate-vocabs 10 && drush generate-users 10 && drush generate-content 200
#   fi
# }

# # Syncs the test files to local.
# function sync_drupal_files () {
#   if [[ -z "$1" ]]; then
#     echo -e "\033[1;31mError: provide drush alias.\033[0m"
#   else
#     echo -e "\n\033[0;32mSyncing the ($1) files\033[0m"
#     drush -y rsync @$1_t:%files @$1:%files
#   fi
# }

# # Create a new multisite.
# function new_multisite() {
#   if [[ -z "$1" ]]; then
#     echo -en "\n\033[0;32mEnter site name\033[0m: "; read site
#   fi
#   site=${site:-$1} && module="${site}_mod" && theme="${site}_the"
#   echo -e "\n\033[0;32mNew (\033[0m$site\033[0;32m) multisite\033[0m"

#   echo -e "\n\033[0;32mCreate folder structure\033[0m"
#   mkdir -p $DRUPAL_ROOT/sites/$site/{libraries,modules/{contrib,custom/$module,features},themes/$theme/templates,files}
#   cp $DRUPAL_ROOT/sites/default/default.settings.php $DRUPAL_ROOT/sites/$site/settings.php

#   echo -e "\n\033[0;32mCreate custom module\033[0m"
#   echo -e "name = $module\ndescription = Custom hooks, callbacks and code.\ncore = 7.x\npackage = $site\n" >> $DRUPAL_ROOT/sites/$site/modules/custom/$module/$module.info
#   echo -e "<?php\n" >> $DRUPAL_ROOT/sites/$site/modules/custom/$module/$module.module
#   echo -e "<?php\n" >> $DRUPAL_ROOT/sites/$site/modules/custom/$module/$module.install

#   echo -e "\n\033[0;32mCreate custom theme\033[0m"
#   echo -e "name = $theme\ndescription = Custom $theme Theme\ncore = 7.x\n" >> $DRUPAL_ROOT/sites/$site/themes/$theme/$theme.info
#   echo -e "<?php\n" >> $DRUPAL_ROOT/sites/$site/themes/$theme/template.php

#   echo -e "\n\033[0;32mCreate patches file\033[0m"
#   echo -e "" >> $DRUPAL_ROOT/sites/$site/PATCHES.txt

#   echo -e "\n\033[0;32mSet permissions\033[0m"
#   chmod o+w $DRUPAL_ROOT/sites/$site/settings.php && chmod o+w $DRUPAL_ROOT/sites/$site/files
# }