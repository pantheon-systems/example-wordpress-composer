#!/bin/bash

if [[ (${CURRENT_BRANCH} != "master" && -z ${CI_PR_URL+x}) || (${CURRENT_BRANCH} == "master" && -n ${CI_PR_URL+x}) ]];
then
    echo -e "CI will only run Behat tests on Pantheon if on the master branch or creating a pull requests.\n"
    exit 0;
fi

echo "::::::::::::::::::::::::::::::::::::::::::::::::"
echo "Behat clean up on site: $TERMINUS_SITE.$TERMINUS_ENV"
echo "::::::::::::::::::::::::::::::::::::::::::::::::"
echo

# Restore the backup made before testing
terminus -n backup:restore $TERMINUS_SITE.$TERMINUS_ENV --element=database --yes