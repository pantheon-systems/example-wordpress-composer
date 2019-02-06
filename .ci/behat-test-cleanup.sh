#!/bin/bash

echo "::::::::::::::::::::::::::::::::::::::::::::::::"
echo "Behat clean up on site: $TERMINUS_SITE.$TERMINUS_ENV"
echo "::::::::::::::::::::::::::::::::::::::::::::::::"
echo

# Restore the backup made before testing
terminus -n backup:restore $TERMINUS_SITE.$TERMINUS_ENV --element=database --yes