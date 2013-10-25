<?php

$aliases = array();
$drupal_root = $_ENV["DRUPAL_ROOT"];

// Automatic alias for each Drupal site
$site = new DirectoryIterator($drupal_root . '/sites');
while ($site->valid()) {
  // Look for directories containing a 'settings.php' file
  if ($site->isDir() && !$site->isDot() && !$site->isLink()) {
    if (file_exists($site->getPathname() . '/settings.php')) {
      // Add site alias
      $basename = $site->getBasename();

      // Local alias
      $aliases[$basename] = array(
        'uri' => $basename,
        'root' => $drupal_root,
        'command-specific' => array(
          'dl' => array(
            'destination' => 'sites/' . $entry . '/modules/contrib'
          )
        ),
        '#test' => '@' . $basename . '_t',
        '#acc' => '@' . $basename . '_a',
        '#prod' => '@' . $basename . '_p',
      );

      // Test alias
      // $aliases[$basename . '_t'] = array();

      // Acceptance alias
      // $aliases[$basename . '_t'] = array();

      // Production alias
      // $aliases[$basename . '_t'] = array();
    }
  }
  $site->next();
}

// =============================================================================

// Get all site aliases
$all = array();
foreach ($aliases as $name => $definition) {
  $all[] = '@' . $name;
}

// 'All' alias group
$aliases['all'] = array(
  'site-list' => $all,
);
