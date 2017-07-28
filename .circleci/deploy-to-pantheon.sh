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

if [[ (${CIRCLE_BRANCH} != "master" && -z ${CIRCLE_PULL_REQUEST+x}) || (${CIRCLE_BRANCH} == "master" && -n ${CIRCLE_PULL_REQUEST+x}) ]];
then
    echo -e "CircleCI will only deploy to Pantheon if on the master branch or creating a pull requests.\n"
    exit 0;
fi

if -n ${CIRCLE_PULL_REQUEST+x} && ! TERMINUS_DOES_MULTIDEV_EXIST ${TERMINUS_ENV}
then
    terminus env:wake -n "$TERMINUS_SITE.dev"
    terminus build:env:create -n "$TERMINUS_SITE.dev" "$TERMINUS_ENV" --clone-content --yes --notify="$NOTIFY"
else
    terminus build:env:push -n "$TERMINUS_SITE.$TERMINUS_ENV" --yes
fi

terminus secrets:set -n "$TERMINUS_SITE.$TERMINUS_ENV" token "$GITHUB_TOKEN" --file='github-secrets.json' --clear --skip-if-empty

# Cleanup old multidevs
terminus build:env:delete:pr -n "$TERMINUS_SITE" --yes
