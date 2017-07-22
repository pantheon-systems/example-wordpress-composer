#!/bin/bash

set -ex

echo "Begin build for $CIRCLE_ENV${PR_ENV:+ for }$PR_ENV. Pantheon test environment is $TERMINUS_SITE.$TERMINUS_ENV"

# Add a Git token for Composer
if [ -n "$GITHUB_TOKEN" ] ; then
  composer config --global github-oauth.github.com $GITHUB_TOKEN
fi

# Enable Composer parallel downloads
composer global require -n "hirak/prestissimo:^0.3"

# Build assets with Composer
composer -n build-assets

# Compile Sass or run any other build steps necessary