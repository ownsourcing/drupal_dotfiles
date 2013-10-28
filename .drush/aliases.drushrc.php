<?php

$aliases = array();
$drupal_root = $_SERVER["DRUPAL_ROOT"];

// Automatic alias for each Drupal site
$site = new DirectoryIterator($drupal_root . '/sites');
while ($site->valid()) {
  // Look for directories containing a 'settings.php' file
  if ($site->isDir() && !$site->isDot() && !$site->isLink()) {
    if (file_exists($site->getPathname() . '/settings.php')) {
      // Add site alias
      $basename = $site->getBasename();

      // Development (local) stage.
      $aliases[$basename] = array(
        'uri' => $basename,
        'root' => $drupal_root,
        'command-specific' => array(
          'dl' => array(
            'destination' => 'sites/' . $basename . '/modules/contrib'
          )
        ),
        '#test' => '@' . $basename . '_t',
        '#acc' => '@' . $basename . '_a',
        '#prod' => '@' . $basename . '_p',
      );

      // Testing stage.
      // $aliases[$basename . '_t'] = array(
          // '#dev' => '@' . $basename,
          // '#acc' => '@' . $basename . '_a',
          // '#prod' => '@' . $basename . '_p',
      // );

      // Acceptance stage.
      // $aliases[$basename . '_a'] = array(
          // '#dev' => '@' . $basename,
          // '#test' => '@' . $basename . '_t',
          // '#prod' => '@' . $basename . '_p',
      // );

      // Production stage.
      // $aliases[$basename . '_p'] = array(
          // '#dev' => '@' . $basename,
          // '#test' => '@' . $basename . '_t',
          // '#acc' => '@' . $basename . '_a',
      // );
    }
  }
  $site->next();
}

// Get all site aliases
$all = array();
foreach ($aliases as $name => $definition) {
  $all[] = '@' . $name;
}

// 'All' alias group
$aliases['all'] = array(
  'site-list' => $all,
);
