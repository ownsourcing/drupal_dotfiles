<?php
/**
 * @file(debug.drush.inc)
 */

/**
 * [debug_drush_command description]
 * @return [type] [description]
 */
function debug_drush_command() {
  return array(
    'debug' => array(
      'description' => "Resets the dev location in the language table.",
      'bootstrap' => DRUSH_BOOTSTRAP_DRUPAL_FULL,
    ),
  );
}

/**
 * [drush_debug description]
 * @return [type] [description]
 */
function drush_debug() {
  module_enable(array('devel', 'diff'));
  db_query("INSERT IGNORE INTO `role_permission` (rid, permission, module) VALUES (1, 'access devel information', 'devel'), (2, 'access devel information', 'devel'), (2, 'access devel information', 'devel')");
}

