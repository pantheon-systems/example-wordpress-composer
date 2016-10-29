#!/bin/bash

# Echo commands as they are executed, but don't allow errors to stop the script.
set -x

# Only delete old environments if there is a pattern defined to
# match environments eligible for deletion.
if [ -z "$MULTIDEV_DELETE_PATTERN" ] ; then
  exit 0
fi

# List all but the newest two environments.
OLDEST_ENVIRONMENTS=$(terminus site environments --format=bash | sort -k2 | cut -d ' ' -f 1 | grep "$MULTIDEV_DELETE_PATTERN" | sed -e '$d' | sed -e '$d')

# Exit if there are no environments to delete
if [ -z "$OLDEST_ENVIRONMENTS" ] ; then
  exit 0
fi

# Go ahead and delete the oldest environments.
for ENV_TO_DELETE in $OLDEST_ENVIRONMENTS ; do
  terminus site delete-env --env=$ENV_TO_DELETE --yes
done
