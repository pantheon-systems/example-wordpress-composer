#!/bin/bash

if [[ ${CURRENT_BRANCH} != "master" && -z ${CI_PR_URL} ]];
then
  echo -e "CI will only deploy to Pantheon if on the master branch or creating a pull requests.\n"
  exit 0;
fi

echo "::::::::::::::::::::::::::::::::::::::::::::::::"
echo "Behat clean up on site: $TERMINUS_SITE.$TERMINUS_ENV"
echo "::::::::::::::::::::::::::::::::::::::::::::::::"
echo

# Restore the backup made before testing
terminus -n backup:restore $TERMINUS_SITE.$TERMINUS_ENV --element=database --yes

# Clear site cache
terminus -n env:clear-cache $TERMINUS_SITE.$TERMINUS_ENV