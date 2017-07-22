#!/bin/bash

set -ex

echo "Begin build for $CIRCLE_ENV${PR_ENV:+ for }$PR_ENV. Pantheon test environment is $TERMINUS_SITE.$TERMINUS_ENV"

# Build assets with Composer
composer -n build-assets

# Compile Sass or run any other build steps necessary