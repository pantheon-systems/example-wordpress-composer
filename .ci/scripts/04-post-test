#!/bin/bash

set -eo pipefail

#
# This script runs any post-test operations that may be needed.
#

terminus -n secrets:set "$TERMINUS_SITE.$TERMINUS_ENV" token "$GITHUB_TOKEN" --file='github-secrets.json' --clear --skip-if-empty
