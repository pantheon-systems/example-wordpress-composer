#!/bin/bash

set -ex

BASH_ENV=~/.bashrc

#=====================================================================================================================
# Start EXPORTing needed environment variables
# Bitbucket does not yet expand environment variables so they have to be manually EXPORTed.
# The resulting ~/.bashrc must also be manually sourced on every step that needs these variables.
# https://bitbucket.org/site/master/issues/18262/feature-request-pipeline-command-to-modify
#=====================================================================================================================

# Set CI variables
echo 'export BRANCH=$(echo $BITBUCKET_BRANCH | grep -v '"'"'^\(master\|[0-9]\+.x\)$'"'"')' >> $BASH_ENV
echo 'export CI_ENV=ci-$BITBUCKET_BUILD_NUMBER' >> $BASH_ENV
echo 'export CURRENT_BRANCH=$BITBUCKET_BRANCH' >> $BASH_ENV
echo 'export CI_PR_URL=BITBUCKET_PR_ID' >> $BASH_ENV
echo 'export BEHAT_ADMIN_PASSWORD=$(openssl rand -base64 24)' >> $BASH_ENV
echo 'export BEHAT_ADMIN_USERNAME=pantheon-ci-testing-$BITBUCKET_BUILD_NUMBER' >> $BASH_ENV
echo 'export BEHAT_ADMIN_EMAIL=no-reply+ci-$BITBUCKET_BUILD_NUMBER@getpantheon.com' >> $BASH_ENV


# Configure git credentials
git config --global user.email "$GIT_EMAIL"
git config --global user.name "BitbucketPipelinesCI"

source $BASH_ENV

echo 'export PATH=$PATH:$HOME/bin:$HOME/terminus/bin' >> $BASH_ENV
echo 'export PR_ENV=${BRANCH:+pr-$BRANCH}' >> $BASH_ENV

source $BASH_ENV

# If we are on a pull request
if [[ $BITBUCKET_BRANCH != "master" && -n "$BITBUCKET_PR_ID" ]]
then
    # Then use a pr- branch/multidev
    PR_NUMBER=${BITBUCKET_PR_ID##*/}
    PR_BRANCH="pr-${PR_NUMBER}"
    echo "export DEFAULT_ENV=pr-${PR_NUMBER}" >> $BASH_ENV
else
    # otherwise make the branch name multidev friendly
    if [[ $BITBUCKET_BRANCH == "master" ]]
    then
        echo "export DEFAULT_ENV=dev" >> $BASH_ENV
    else
        echo 'export DEFAULT_ENV=$(echo ${PR_ENV:-$CI_ENV} | tr '"'"'[:upper:]'"'"' '"'"'[:lower:]'"'"' | sed '"'"'s/[^0-9a-z-]//g'"'"' | cut -c -11 | sed '"'"'s/-$//'"'"')' >> $BASH_ENV
    fi
fi

echo 'export TERMINUS_SITE=${TERMINUS_SITE:-$BITBUCKET_REPO_SLUG}' >> $BASH_ENV
echo 'export TERMINUS_ENV=${TERMINUS_ENV:-$DEFAULT_ENV}' >> $BASH_ENV
source $BASH_ENV

if [[ $BITBUCKET_BRANCH != "master" && -z "$BITBUCKET_PR_ID" ]];
then
  echo -e "CI will only deploy to Pantheon if on the master branch or creating a pull requests.\n"
  exit 0;
fi

#===========================================
# End EXPORTing needed environment variables
#===========================================

# Add a Git token for Composer
# TODO: Is there any point in doing this for Bitbucket? Might we need $GITHUB_TOKEN for Composer even when running on Bitbucket?
if [ -n "$GITHUB_TOKEN" ] ; then
  composer config --global github-oauth.github.com $GITHUB_TOKEN
fi

# Bail on errors
set +ex

# Make sure Terminus is installed
terminus --version

# Authenticate with Terminus
terminus auth:login -n --machine-token="$TERMINUS_TOKEN"

# Disable host checking
mkdir -p $HOME/.ssh && echo "StrictHostKeyChecking no" >> "$HOME/.ssh/config"

# Ignore file permissions.
git config --global core.fileMode false
