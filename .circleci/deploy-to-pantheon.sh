#!/bin/bash

set -ex

# Stash list of Pantheon multidev environments
PANTHEON_MULTIDEV_LIST="$(terminus multidev:list -n ${PANTHEON_SITE} --format=list --field=Name)"

if [[ $CIRCLE_BRANCH == "master" ]]
then
    terminus build:env:merge -n "$TERMINUS_SITE.$TERMINUS_ENV" --yes
else
    # If we are not on master or PR abort
    if [[ -n ${CIRCLE_PULL_REQUEST+x} ]]
    then

        # Create a new multidev if needed
        if ! terminusMultiDevExists ${TERMINUS_ENV}
        then
            # Wake dev so we can clone the database
            terminus env:wake -n "$TERMINUS_SITE.dev"
            terminus build:env:create -n "$TERMINUS_SITE.dev" "$TERMINUS_ENV" --clone-content --yes --notify="$NOTIFY"
        else
            # Otherwise push code to the existing multidev
            terminus build-env:push-code -n $TERMINUS_SITE.$TERMINUS_ENV
        fi
    else
        echo -e "CircleCI will only deploy to Pantheon for master or pull requests.\n"
    fi
fi

# Cleanup old multidevs
terminus build:env:delete:pr -n "$TERMINUS_SITE" --preserve-prs --delete-branch --yes

terminusMultiDevExists()
{
    while read -r multiDev; do
        if [[ "${multiDev}" == "$1" ]]
        then
            return 0;
        fi
    done <<< "$PANTHEON_MULTIDEV_LIST"

    return 1;
}