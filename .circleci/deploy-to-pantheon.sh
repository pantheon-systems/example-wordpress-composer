#!/bin/bash

set -ex

if [[ $CIRCLE_BRANCH == "master" ]]
then
    terminus build:env:merge -n "$TERMINUS_SITE.$TERMINUS_ENV" --yes
    terminus build:env:delete:pr -n "$TERMINUS_SITE" --yes
else
    # Cleanup old multidevs
    terminus build:env:delete:ci -n "$TERMINUS_SITE" --keep=2 --yes

    # Wake the dev environment
    terminus env:wake -n "$TERMINUS_SITE.dev"

    # Create a new multidev
    terminus build:env:create -n "$TERMINUS_SITE.dev" "$TERMINUS_ENV" --clone-content --yes --notify="$NOTIFY"
fi