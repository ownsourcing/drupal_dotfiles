#!/bin/bash

# Fetches options.
function get_options() {
  version=$DRUPAL_VERSION_DEFAULT
  site="default"

  while getopts v:s: opt; do
    case $opt in
      v)
        version=$OPTARG
        ;;
      s)
        site=$OPTARG
        ;;
      \?)
        echo "Invalid option: -$OPTARG" >&2
        ;;
    esac
  done
  OPTIND=1

  version_key="${DRUPAL_VERSION_KEY[$version]}"
  drupal_root="$DRUPAL_BASE_FOLDER/$version_key"
  site_test="${site}_t"
  site_db_name="${version_key}_${site}"
  custom_module="${site}_mod"
  custom_theme="${site}_the"
}

# Download Drupal in default folder.
function core-download() {
  get_options "$@"

  echo -e "\n\033[0;32mDownloading Drupal $version.\033[0m"

  if [ -d "$drupal_root" ]; then
    echo -e "\n\033[0;31m$drupal_root already exist.\033[0m"
    return 0
  fi

  # Download Drupal core.
  drush dl "drupal-$version" --destination="$DRUPAL_BASE_FOLDER" --drupal-project-rename="$version_key" -y

  # Create sites file.
  echo -e "<?php\n\n\$uri = '$version_key';\n\n// Automatic multisiter\n\$site = new DirectoryIterator(__DIR__);\nwhile (\$site->valid()) {\n\t// Look for directories containing a 'settings.php' file\n\tif (\$site->isDir() && !\$site->isDot() && !\$site->isLink()) {\n\t\tif (file_exists(\$site->getPathname() . '/settings.php')) {\n\t\t\t// Add site alias\n\t\t\t\$basename = \$site->getBasename();\n\t\t\t\$sites[\$basename . '.' . \$uri] = \$basename;\n\t\t}\n\t}\n\t\$site->next();\n}" > $drupal_root/sites/sites.php

  # Download contrib modules.
  drush dl devel potx coder -y
  return 1
}

# Update the Drupal core.
function core-update() {
  get_options "$@"

  echo -e "\n\033[0;32mUpdating Drupal $version.\033[0m"

  if [ ! -d "$drupal_root/sites/$site" ]; then
    echo -e "\n\033[0;31mDirectory ($drupal_root/sites/$site)\033[0m doesn't exist."
    return 0
  fi

  cd $drupal_root/sites/$site && drush up
  return 1
}

# Install Drupal site.
function site-install() {
  get_options "$@"

  echo -e "\n\033[0;32mInstall ($site) site in Drupal $version core.\033[0m"

  if [ -d "$drupal_root/sites/$site" ]; then
    echo -e "\n\033[0;31mDirectory ($drupal_root/sites/$site)\033[0m already exist."
    open http://$site.${version_key}
    return 0
  fi

  # Create folder structure.
  mkdir -p $drupal_root/sites/$site/{libraries,modules/{contrib,custom/$custom_module,features},themes/{contrib,custom/$custom_theme/templates},files} && chmod -R o+w $drupal_root/sites/$site/files && cd $drupal_root/sites/$site

  # Install site.
  drush si minimal --db-url=mysql://$MYSQL_USER:$MYSQL_PASS@localhost/$site_db_name --site-name=$site --sites-subdir=$site -y

  # Configure site.
  drush vset file_public_path "sites/$site/files/public" && drush en devel potx coder update statistics simpletest -y

  # Add DNS entry.
  sudo sed -ie "\|^127.0.0.1 ${site}.${version_key}|d" /private/etc/hosts && sudo sh -c "echo 127.0.0.1 ${site}.${version_key} >> /private/etc/hosts"

  # Create custom module
  echo -e "name = ${module}\ndescription = Custom hooks, callbacks and code.\ncore = $version.x\npackage = ${site}\n" >> $drupal_root/sites/$site/modules/custom/$custom_module/$custom_module.info && echo -e "<?php\n" >> $drupal_root/sites/$site/modules/custom/$custom_module/$custom_module.module && echo -e "<?php\n" >> $drupal_root/sites/$site/modules/custom/$custom_module/$custom_module.install

  # Create custom theme
  echo -e "name = ${theme}\ndescription = Custom ${theme} Theme\ncore = $version.x\n" >> $drupal_root/sites/$site/themes/custom/$custom_theme/$custom_theme.info && echo -e "<?php\n" >> $drupal_root/sites/$site/themes/custom/$custom_theme/template.php

  # Create patches file
  echo -e "This file is intended to collect urls for patches, that you've applied in Drupal core / contrib modules." >> $drupal_root/sites/$site/PATCHES.txt

  # Open the new site in the default browser.
  open http://$site.$version_key
  return 1
}


















function simpletest_project() {
  if [[ -z "$1" ]]; then
    echo -en "\n\033[0;32mEnter module / theme name\033[0m: "; read project
  fi
  project=${1:-$project} && site="st_${project}"

  echo -e "\n\033[0;32mSimpletest: \033[0m$project"
  site-install $site false
  pm-download $project $site
  echo -e "\n\033[0;32mOpen $site in browser:\033[0m"
  open http://$site.d7
}

# function site-install() {
#   if [[ -z "$1" ]]; then
#     dir=${PWD##*/}
#     echo -en "\n\033[0;32mEnter site name\033[0m [$dir]: "; read site && site=${site:=$dir}
#   else
#     site=$1
#   fi
#   clear && cd $QUADRUPAL7_PATH/sites/$site/ && site_t="${site}_t" && db_name="dev_${site}" && repo="${site}"

#   open_in_browser=${2:-true}
#   if [ ! -d "$DRUPAL_ROOT/sites/$site" ]; then
#     echo -e "\n\033[0;32mAdd multisite:\033[0m"
#     cd $DRUPAL_ROOT/sites
#     mkdir -p $DRUPAL_ROOT/sites/$site/{libraries,modules/{contrib,custom/$module,features},themes/$theme/templates,files/{public,private}} && chmod -R o+w $DRUPAL_ROOT/sites/$site/files
#     drush si minimal --db-url=mysql://$MYSQL_USER:$MYSQL_PASS@localhost/$site --site-name=$site --sites-subdir=$site -y
#     echo -e "\n\033[0;32mConfigure multisite:\033[0m"
#     cd $DRUPAL_ROOT/sites/$site
#     drush vset file_public_path "sites/$site/files/public"
#     drush vset file_private_path "sites/$site/files/private"
#     echo -e "\n\033[0;32mAdd DNS entry:\033[0m"
#     sudo sed -ie "\|^127.0.0.1 ${site}.d7|d" /private/etc/hosts && echo -e "127.0.0.1 ${site}.d7" >> /private/etc/hosts
#     if [ open_in_browser ]; then
#       echo -e "\n\033[0;32mOpen $site in browser:\033[0m"
#       open http://$site.d7
#     fi
#   fi
# }

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
  echo -e "\n\033[0;32mDisable and uninstall ($project) module:\033[0m"
  cd $DRUPAL_ROOT/sites/$site && drush dis $project -y && drush pm-uninstall $project -y
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
