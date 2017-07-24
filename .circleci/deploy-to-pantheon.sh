#!/bin/bash

set -ex

TERMINUS_DOES_MULTIDEV_EXIST()
{
    # Stash list of Pantheon multidev environments
    PANTHEON_MULTIDEV_LIST="$(terminus multidev:list -n ${TERMINUS_SITE} --format=list --field=Name)"

    while read -r multiDev; do
        if [[ "${multiDev}" == "$1" ]]
        then
            return 0;
        fi
    done <<< "$PANTHEON_MULTIDEV_LIST"

    return 1;
}

if [[ $CIRCLE_BRANCH == "master" ]]
then
    terminus build:env:push -n "$TERMINUS_SITE.$TERMINUS_ENV" --yes
    terminus secrets:set -n "$TERMINUS_SITE.$TERMINUS_ENV" token "$GITHUB_TOKEN" --file='github-secrets.json' --clear --skip-if-empty
else
    # Only continue outside of master when building a pull request
    if [[ -n ${CIRCLE_PULL_REQUEST+x} ]]
    then
        # Create a new multidev if needed
        if ! TERMINUS_DOES_MULTIDEV_EXIST ${TERMINUS_ENV}
        then
            # Wake dev so we can clone the database
            terminus env:wake -n "$TERMINUS_SITE.dev"
            terminus build:env:create -n "$TERMINUS_SITE.dev" "$TERMINUS_ENV" --clone-content --yes --notify="$NOTIFY"
        else
            # Otherwise push code to the existing multidev
            terminus build:env:push -n $TERMINUS_SITE.$TERMINUS_ENV
        fi
        terminus secrets:set -n "$TERMINUS_SITE.$TERMINUS_ENV" token "$GITHUB_TOKEN" --file='github-secrets.json' --clear --skip-if-empty
    else
        echo -e "CircleCI will only deploy to Pantheon for master or pull requests.\n"
    fi
fi

# Cleanup old multidevs
terminus build:env:delete:pr -n "$TERMINUS_SITE" --preserve-prs --delete-branch --yes