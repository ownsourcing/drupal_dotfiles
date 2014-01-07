#!/bin/bash

# status message.
function status() { echo -e "\n\033[0;32m$1:\033[0m $2"; }
# warning message.
function warning() { echo -e "\n\033[0;33m$1:\033[0m $2"; }
# error message
function error() { echo -e "\n\033[0;31m$1:\033[0m $2"; }
# Writes $1 into $2.
function write_to_file() { echo -e $1 >> $2; }
# Download Drupal in default folder.
function core_download() { get_user_options "$@";
#_check_multisite;
}
# Install Drupal site.
function site_install() { get_user_options "$@"; _check_multisite; }
# Update the Drupal core.
function site_update() { get_user_options "$@"; _update_multisite; }
# Removes Drupal site.
function site_delete() { get_user_options "$@"; _delete_multisite; }
# Sync the test site DB to your local site.
function sql_sync() { get_user_options "$@"; _synchronize_database; }
# Fetches options.
function get_user_options() {
  clear
  distro_index=${1:-$DRUPAL_DISTRO_DEFAULT};
  site=${2:-"default"};

  while getopts d:s:p: opt; do
    case $opt in
      d)
        distro=$OPTARG
        ;;
      s)
        site=$OPTARG
        ;;
      p)
        install_profile=$OPTARG
        ;;
      \?)
        echo "Invalid option: -$OPTARG" >&2
        ;;
    esac
  done
  OPTIND=1

  distro="${DRUPAL_DISTRO_KEY[$distro_index]}"
  _check_base
  _check_distro

  # echo -en "\n\033[0;32mThis site??\033[0m ($site_suggestion): " && read retrieve && site=${retrieve:-$site_suggestion};
  # version_key="${DRUPAL_VERSION_KEY[$version]}"
  # drupal_root="$DRUPAL_BASE_FOLDER/$version_key"
  # site_alias="${version_key}_${site}"
  # site_alias_test="${version_key}_${site}_t"
  # site_db_name="${version_key}_${site}"
  # custom_module="${site}_mod"
  # custom_theme="${site}_the"
}

function _check_base() {
  local path=${1:-$DRUPAL_BASE_FOLDER};

  if [ -d $path ]; then
    warning "Folder already exist" "$path";
  else
    status "Create base folder" "$path";
    mkdir -p $path;
  fi
}
function _check_distro() {
  local repo=${1:-${DRUPAL_GIT_REPO[$distro_index]}};
  local path=${2:-$DRUPAL_BASE_FOLDER/$distro};

  if [ -d $path ]; then
    warning "Folder already exist" "$path";
  else
    _git_clone $repo $path;
    _check_sites_php $path/sites;
    _check_sublime_project $distro $path;
  fi
}
function _check_sites_php() {
  local path=${1:-$DRUPAL_BASE_FOLDER/$distro/sites};

  if [ -f $path/sites.php ]; then
    warning "File already exist" "$path/sites.php";
  else
    status "Create sites.php file" "$distro";
    cp $path/example.sites.php $path/sites.php;
    write_to_file "\n\n\$uri = '$distro';\n\n// Automatic multisiter\n\$site = new DirectoryIterator(__DIR__);\nwhile (\$site->valid()) {\n\t// Look for directories containing a 'settings.php' file\n\tif (\$site->isDir() && !\$site->isDot() && !\$site->isLink()) {\n\t\tif (file_exists(\$site->getPathname() . '/settings.php')) {\n\t\t\t// Add site alias\n\t\t\t\$basename = \$site->getBasename();\n\t\t\t\$sites[\$basename . '.' . \$uri] = \$basename;\n\t\t}\n\t}\n\t\$site->next();\n}" $path/sites.php;
  fi
}
function _check_sublime_project() {
  local project=${1:-''};
  local path=${2:-$DRUPAL_BASE_FOLDER/$distro/sites/$site};

  if [ -f $path/$project.sublime-project ]; then
    warning "File already exist" "($path/$project.sublime-project)";
  else
    status "Create sublime project" "$project";
    write_to_file "\n{\n\t\"folders\":\n\t[\n\t\t{\n\t\t\t\"path\": \"$path\"\n\t\t}\n\t]\n}" $path/$project.sublime-project;
  fi
  /Applications/Sublime\ Text\ 2.app/Contents/SharedSupport/bin/subl -n --project $path/$project.sublime-project
}
function _check_patches_txt() {
  local path=${1:-$DRUPAL_BASE_FOLDER/$distro/sites/$site};

  if [ -f $path/PATCHES.txt ]; then
    warning "File already exist" "$path/PATCHES.txt";
  else
    status "Create an PATCHES.txt file" "$site";
    write_to_file "This file is intended to collect urls for patches, that you've applied in Drupal core / contrib modules." $path/PATCHES.txt;
  fi
}
function _check_custom_module() {
  local module=${1:-''};
  local path=${2:-$DRUPAL_BASE_FOLDER/$distro/sites/$site};

  _check_files_folder $path/modules/custom/$module;

  if [ -d $path/modules/custom/$module ]; then
    warning "Module already exist" "$module";
  else
    status "Create an custom module" "$module";
    write_to_file "name = $module\ndescription = Custom hooks, callbacks and code.\npackage = custom\n" $path/modules/custom/$module/$module.info;
    write_to_file "<?php\n" $path/modules/custom/$module/$module.module;
    write_to_file "<?php\n" $path/modules/custom/$module/$module.install;
  fi
}
function _check_custom_theme() {
  local theme=${1:-''};
  local path=${2:-$DRUPAL_BASE_FOLDER/$distro/sites/$site};

  _check_files_folder $path/themes/custom/$theme;

  if [ -d $path/themes/custom/$theme ]; then
    warning "Theme already exist" "$theme";
  else
    status "Create an custom theme" "$theme";
    write_to_file "name = $theme\ndescription = Custom $theme Theme\n" $path/themes/custom/$theme/$theme.info
    write_to_file "<?php\n" $path/themes/custom/$theme/template.php
  fi
}
function _check_dns_mapping() {
  local uri=${1:-''};

  status "Add ($uri) to hosts";
  sudo sed -ie "\|^127.0.0.1 $uri|d" /private/etc/hosts;
  sudo sh -c "echo 127.0.0.1 $uri >> /private/etc/hosts";
}
function _check_files_folder() {
  local path=${1:-$DRUPAL_BASE_FOLDER/$distro/sites/$site};

  if [ -d $path/files ]; then
    warning "Folder already exist" "$path/files";
  else
    status "Create folder" "$path/files";
    mkdir -p $path/files;
  fi
  status "Set permissions of files folder" "$site";
  chmod -R a+w $path/files/;
}
function _check_folder_structure() {
  local path=${1:-$DRUPAL_BASE_FOLDER/$distro/sites/$site};

  if [ -d $path/files ]; then
    warning "Structure already exist" "$path/files";
  else
    status "Create folder structure" "$path";
    mkdir -p $path/{libraries,modules/{contrib,custom,features},themes/{contrib,custom},files};
  fi
}
function _check_url() {
  local url=${1:-''};

  status "Open url in your default browser" "$url";
  open $url
}
function _check_multisite() {
  local path=${1:-$DRUPAL_BASE_FOLDER/$distro/sites/$site};
  local db_name=${2:-"$distro_$site"};
  local install_profile=${3:-'minimal'};

  # Checkout repository (if any).
  if [ ! -d $path ]; then
    _git_clone $site $path;
    _update_settings_php $path;
  fi

  # Create new multisite.
  if [ ! -d $path ]; then
    _check_folder_structure $path
    cd $path
    status "Install multisite" "$site";
    drush si $install_profile --db-url=mysql://$MYSQL_USER:$MYSQL_PASS@localhost/$db_name --site-name=$site --sites-subdir=$site -y;
    status "Configure ($site) local / development."; drush en devel potx coder update statistics simpletest -y
    _update_settings_php $path;
    _check_files_folder $path;
    _check_dns_mapping "$site.$distro";
    _check_custom_module "${site}mod" $path;
    _check_custom_theme "$site" $path;
    _check_patches_txt;
    _check_url http://$site.$distro;
    _check_sublime_project "$distro_$site" $path;
  fi
}
function _update_multisite() {
  local path=${1:-$DRUPAL_BASE_FOLDER/$distro/sites/$site};

  if [ ! -d path ]; then
    error "Directory doesn't exist" "$path";
  fi
  status "Updating multisite" "($site)";
  cd $path;
  drush up
}
function _delete_multisite() {
  local path=${1:-$DRUPAL_BASE_FOLDER/$distro/sites/$site};
  local db_name=${2:-"$distro_$site"};

  if [ ! -d path ]; then error "Directory doesn't exist" "$path"; fi
  if [ "$site" == "default" ]; then error "You shouldn't remove the ($site) folder."; fi

  cd $path
  status "Drop database" "$db_name";
  mysql -u $MYSQL_USER -p$MYSQL_PASS -e "DROP DATABASE $db_name;";
  # drush sql-drop @$site;
  status "Remove folder" "$path"; sudo rm -rf $path
}
function _git_clone() {
  local repo=${1:-${DRUPAL_GIT_REPO[$distro_index]}};
  local path=${2:-$DRUPAL_BASE_FOLDER/$distro};

  if [ ! -d $path ]; then
    for git_host in "${GIT_HOSTS[@]}"; do
      git ls-remote "$git_host/$repo.git" &>-
      if [ "$?" -eq 0 ]; then
        status "Clone ($repo) to ($path)";
        git clone $git_host/$repo $path;
      fi
    done
  fi
}
function _update_settings_php() {
  local path=${1:-$DRUPAL_BASE_FOLDER/$distro/sites/$site};

  if [ ! -f $path/settings.php ]; then
    status "Copy settings.php file" "$path";
    cp $DRUPAL_BASE_FOLDER/$distro/sites/default/default.settings.php $path/settings.php;
  fi
  chmod a+w $path/settings.php;
  write_to_file "\n// -----------------------------------------------------------------------------\n// Local settings\n// -----------------------------------------------------------------------------\n\n// APACHE\nini_set('memory_limit', '512M');\nerror_reporting(E_ALL);\nini_set('display_errors', TRUE);\nini_set('display_startup_errors', TRUE);\n\n// DOMAIN\n// \$base_url = 'http://$site.$distro';\n// \$cookie_domain = '.$site.$distro';\n\n// DEVEL\n\$conf['securepages_enable'] = FALSE;\n\$conf['devel_enable'] = TRUE;\n\$conf['reroute_email_enable'] = TRUE;\n\$conf['cache'] = FALSE;\n\$conf['block_cache'] = FALSE;\n\$conf['preprocess_css'] = FALSE;\n\$conf['preprocess_js'] = FALSE;\n\$conf['error_level'] = 2;\n\n// LANGUAGE\n// \$conf['language_default'] = (object) array(\n\t //'language' => 'en',\n\t //'name' => 'English',\n\t //'native' => 'English',\n\t //'direction' => 0,\n\t //'enabled' => 1,\n\t //'plurals' => 0,\n\t //'formula' => '',\n\t //'domain' => '',\n\t //'prefix' => '',\n\t //'weight' => 0,\n\t //'javascript' => '',\n //);\n\n// FILES\n\$conf['file_public_path'] = 'sites/$site/files';\n" $path/settings.php
  chmod a-w $path/settings.php;
}
function _synchronize_database() {
  local site_alias="${distro}_${site}"
  local site_alias_test="${distro}_${site}_t"

  drush -y sql-sync @$site_alias_test @$site_alias
}
function _cache_clear() {
  if [[ -z "$1" ]]; then
    drush cc theme-registry;
    drush cc css-js;
    drush cc block;
    drush cc menu;
    drush cc views
  else
    drush cc $@
  fi
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
