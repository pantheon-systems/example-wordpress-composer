#!/bin/bash

set -ex

TERMINUS_DOES_MULTIDEV_EXIST()
{    
    # Return 1 if on master since dev always exists
    if [[ ${CIRCLE_BRANCH} == "master" ]]
    then
        return 1;
    fi

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

# I don't know if on non-pull requests CIRCLE_PULL_REQUEST is empty or complete
# absent -z will return true in either cases.
if [[ ${CIRCLE_BRANCH} != "master" && -z ${CIRCLE_PULL_REQUEST} ]];
then
    echo -e "CircleCI will only deploy to Pantheon if on the master branch or creating a pull requests.\n"
    exit 0;
fi

if ! TERMINUS_DOES_MULTIDEV_EXIST ${TERMINUS_ENV}
then
    terminus env:wake -n "$TERMINUS_SITE.dev"
    terminus build:env:create -n "$TERMINUS_SITE.dev" "$TERMINUS_ENV" --clone-content --yes --notify="$NOTIFY"
else
    terminus build:env:push -n "$TERMINUS_SITE.$TERMINUS_ENV" --yes
fi

terminus secrets:set -n "$TERMINUS_SITE.$TERMINUS_ENV" token "$GITHUB_TOKEN" --file='github-secrets.json' --clear --skip-if-empty

# Cleanup old multidevs
terminus build:env:delete:pr -n "$TERMINUS_SITE" --yes
