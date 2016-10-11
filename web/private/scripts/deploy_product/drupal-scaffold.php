<?php

chdir(getenv('HOME') . '/code');

print "\n====== Running 'composer drupal-scaffold' ======\n\n";
passthru('composer drupal-scaffold  2>&1');
