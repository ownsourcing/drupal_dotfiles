#!/bin/bash

# Prints $1 nicely styled.
function print() { echo -e "\n\033[0;32m$1\033[0m"; }

# Prints $1 error styled.
function error() { echo -e "\n\033[0;31m[ERROR]\033[0m $1"; return 0; }

# Writes $1 into $2.
function write_to_file() { echo -e $1 >> $2; }

# Fetches options.
function get_options() {
  version=$DRUPAL_VERSION_DEFAULT
  site="default"
  [[ -f settings.php ]] && site=${PWD##*/}

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

  if [ -d "$drupal_root" ]; then error "$drupal_root already exist"; fi
  print "Downloading Drupal $version." && drush dl "drupal-$version" --destination="$DRUPAL_BASE_FOLDER" --drupal-project-rename="$version_key" -y
  print "Create ($version) sites.php file." && write_to_file "<?php\n\n\$uri = '$version_key';\n\n// Automatic multisiter\n\$site = new DirectoryIterator(__DIR__);\nwhile (\$site->valid()) {\n\t// Look for directories containing a 'settings.php' file\n\tif (\$site->isDir() && !\$site->isDot() && !\$site->isLink()) {\n\t\tif (file_exists(\$site->getPathname() . '/settings.php')) {\n\t\t\t// Add site alias\n\t\t\t\$basename = \$site->getBasename();\n\t\t\t\$sites[\$basename . '.' . \$uri] = \$basename;\n\t\t}\n\t}\n\t\$site->next();\n}" $drupal_root/sites/sites.php
  print "Download ($version) development modules." && drush dl devel potx coder -y
  print "Create ($version) sublime project." && write_to_file "\n{\n\t\"folders\":\n\t[\n\t\t{\n\t\t\t\"path\": \"$drupal_root\"\n\t\t}\n\t]\n}" $drupal_root/$version_key.sublime-project
}

# Update the Drupal core.
function core-update() {
  get_options "$@"

  if [ ! -d "$drupal_root/sites/$site" ]; then error "Directory ($drupal_root/sites/$site) doesn't exist."; fi
  print "Updating Drupal $version." && cd $drupal_root/sites/$site && drush up
}

# Install Drupal site.
function site-install() {
  get_options "$@"

  if [ -d "$drupal_root/sites/$site" ]; then open http://$site.${version_key} && error "Directory ($drupal_root/sites/$site) already exist."; fi
  print "Install ($site) site in Drupal $version core."
  print "Create ($site) folder structure." && mkdir -p $drupal_root/sites/$site/{libraries,modules/{contrib,custom/$custom_module,features},themes/{contrib,custom/$custom_theme/templates},files} && chmod -R o+w $drupal_root/sites/$site/files && cd $drupal_root/sites/$site
  print "Install ($site) multisite." && drush si --db-url=mysql://$MYSQL_USER:$MYSQL_PASS@localhost/$site_db_name --site-name=$site --sites-subdir=$site -y
  print "Set permissions of ($site) files folder" && chmod -R g+w $drupal_root/sites/$site/files/
  print "Configure ($site) local / development." && drush vset file_public_path "sites/$site/files/public" && drush en devel potx coder update statistics simpletest -y
  print "Add ($site.$version_key) to hosts." && sudo sed -ie "\|^127.0.0.1 ${site}.${version_key}|d" /private/etc/hosts && sudo sh -c "echo 127.0.0.1 ${site}.${version_key} >> /private/etc/hosts"
  print "Create an initial ($custom_module) module." && write_to_file "name = ${module}\ndescription = Custom hooks, callbacks and code.\ncore = $version.x\npackage = ${site}\n" $drupal_root/sites/$site/modules/custom/$custom_module/$custom_module.info && write_to_file "<?php\n" $drupal_root/sites/$site/modules/custom/$custom_module/$custom_module.module && write_to_file "<?php\n" $drupal_root/sites/$site/modules/custom/$custom_module/$custom_module.install
  print "Create an initial ($custom_theme) theme." && write_to_file "name = ${theme}\ndescription = Custom ${theme} Theme\ncore = $version.x\n" $drupal_root/sites/$site/themes/custom/$custom_theme/$custom_theme.info && write_to_file "<?php\n" $drupal_root/sites/$site/themes/custom/$custom_theme/template.php
  print "Create an ($site) PATCHES.txt file." && write_to_file "This file is intended to collect urls for patches, that you've applied in Drupal core / contrib modules." $drupal_root/sites/$site/PATCHES.txt
  print "Open ($site) in your default browser." && open http://$site.$version_key
}

# Trigger drush cache clear.
function cache-clear() {
  if [[ -z "$1" ]]; then
    print "Cache clear on (theme-registry, css-js, block, menu, views)." && drush cc theme-registry && drush cc css-js && drush cc block && drush cc menu && drush cc views
  else
    drush cc $@
  fi
}

# Sync the test site DB to your local site.
function sql-sync() {
  get_options "$@"
  drush -y sql-sync @$site_test @$site
}














# function simpletest_project() {
#   if [[ -z "$1" ]]; then
#     echo -en "\n\033[0;32mEnter module / theme name\033[0m: "; read project
#   fi
#   project=${1:-$project} && site="st_${project}"

#   echo -e "\n\033[0;32mSimpletest: \033[0m$project"
#   site-install $site false
#   pm-download $project $site
#   echo -e "\n\033[0;32mOpen $site in browser:\033[0m"
#   open http://$site.d7
# }

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

# function remove_multisite() {
#   if [[ -z "$1" ]]; then
#     dir=${PWD##*/}
#     echo -en "\n\033[0;32mEnter site name\033[0m [$dir]: "; read site && site=${site:=$dir}
#   else
#     site=$1
#   fi
#   clear && cd $QUADRUPAL7_PATH/sites/$site/ && site_t="${site}_t" && db_name="dev_${site}" && repo="${site}"

#   if [ -d "$DRUPAL_ROOT/sites/$site" ]; then
#     echo -e "\n\033[0;32mRemove Drupal multisite:\033[0m"
#     cd $DRUPAL_ROOT/sites/$site
#     drush sql-drop -y && sudo rm -rf $DRUPAL_ROOT/sites/$site && cd $DRUPAL_ROOT/sites/
#     echo -e "\n\033[0;32mRemove DNS entry:\033[0m"
#     sudo sed -ie "\|^127.0.0.1 ${site}.d7|d" /private/etc/hosts
#   fi
# }

# function pm-download() {
#   if [[ -z "$1" ]]; then
#     echo -en "\n\033[0;32mEnter project name\033[0m: "; read project
#   fi
#   project=${1:-$project}
#   if [[ -z "$2" ]]; then
#     dir=${PWD##*/}
#     echo -en "\n\033[0;32mEnter site name\033[0m [$dir]: "; read site && site=${site:=$dir}
#   else
#     site=$2
#   fi
#   clear && cd $QUADRUPAL7_PATH/sites/$site/ && site_t="${site}_t" && db_name="dev_${site}" && repo="${site}"

#   if [ ! -d "$DRUPAL_ROOT/sites/$site/modules/contrib/$project" ]; then
#     echo -e "\n\033[0;32mDownload and enable ($project) module:\033[0m"
#     cd $DRUPAL_ROOT/sites/$site && drush dl $project -y && drush en $project -y
#   else
#     echo -e "\n\033[0;31m $project module already available\033[0m"
#     cd $DRUPAL_ROOT/sites/$site/modules/contrib/$project
#   fi
# }

# function remove_project() {
#   if [[ -z "$1" ]]; then
#     dir=${PWD##*/}
#     echo -en "\n\033[0;32mEnter site name\033[0m [$dir]: "; read site && site=${site:=$dir}
#   else
#     site=$1
#   fi
#   clear && cd $QUADRUPAL7_PATH/sites/$site/ && site_t="${site}_t" && db_name="dev_${site}" && repo="${site}"

#   if [[ -z "$2" ]]; then
#     echo -en "\n\033[0;32mEnter project name\033[0m: "; read project
#   fi

#   project=${2:-$project}
#   echo -e "\n\033[0;32mDisable and uninstall ($project) module:\033[0m"
#   cd $DRUPAL_ROOT/sites/$site && drush dis $project -y && drush pm-uninstall $project -y
# }

# function generate_content() {
#   drush en devel devel_generate -y
#   drush generate-vocabs 10 && drush generate-users 10 && drush generate-content 200
# }

# function pm-list() {
#   if [[ -z "$1" ]]; then
#     drush pml
#   else
#     drush pml | grep -i $1
#   fi
# }
