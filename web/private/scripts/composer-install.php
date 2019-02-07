<?php

chdir(getenv('HOME') . '/code');

print "\n====== Running 'composer install' ======\n\n";
passthru('composer install 2>&1');
