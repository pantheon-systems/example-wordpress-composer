<?php

chdir(getenv('HOME') . '/code');

print "\n====== Running 'composer prepare-for-pantheon' ======\n\n";
passthru('composer prepare-for-pantheon 2>&1');
