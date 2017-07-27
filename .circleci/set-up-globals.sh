#!/bin/bash

set -ex

#==================================================
# The section would be transferable to a DOCKERFILE
#==================================================

# Update current apt packages
apt-get update

#=========================================================================
# Commands below this line would not be transferable to a docker container
#=========================================================================

# Enable Composer parallel downloads
composer global require -n "hirak/prestissimo:^0.3"

# Install Terminus into ~/terminus
/usr/bin/env COMPOSER_BIN_DIR=$HOME/bin composer --working-dir=$HOME require pantheon-systems/terminus "^1"


#=====================================================================================================================
# Start EXPORTing needed environment variables
# Circle CI 2.0 does not yet expand environment variables so they have to be manually EXPORTed
# Once environment variables can be expanded this section can be removed
# See: https://discuss.circleci.com/t/unclear-how-to-work-with-user-variables-circleci-provided-env-variables/12810/11
# See: https://discuss.circleci.com/t/environment-variable-expansion-in-working-directory/11322
# See: https://discuss.circleci.com/t/circle-2-0-global-environment-variables/8681
#=====================================================================================================================
export PATH=$PATH:$HOME/bin:$HOME/terminus/bin:$HOME/.composer/vendor/bin
export BRANCH=$(echo $CIRCLE_BRANCH | grep -v '^\(master\|[0-9]\+.x\)$')
export PR_ENV=${BRANCH:+pr-$BRANCH}
export CIRCLE_ENV=ci-$CIRCLE_BUILD_NUM
# If we are on a pull request
if [[ $CIRCLE_BRANCH != "master" && -n ${CIRCLE_PULL_REQUEST+x} ]]
then
	# Then use a pr- branch/multidev
	export PR_NUMBER=${CIRCLE_PULL_REQUEST##*/}
	export PR_BRANCH="pr-${PR_NUMBER}"
	export DEFAULT_ENV=pr-${PR_NUMBER}
else
	# otherwise make the branch name multidev friendly
	if [[ $CIRCLE_BRANCH == "master" ]]
	then
		export DEFAULT_ENV=dev
	else
		export DEFAULT_ENV=$(echo ${PR_ENV:-$CIRCLE_ENV} | tr '[:upper:]' '[:lower:]' | sed 's/[^0-9a-z-]//g' | cut -c -11 | sed 's/-$//')
	fi
fi
export TERMINUS_ENV=${TERMINUS_ENV:-$DEFAULT_ENV}

#===========================================
# End EXPORTing needed environment variables
#===========================================

terminus --version

#===============================
# Start Install Terminus Plugins
#===============================
INSTALL_TERMINUS_PLUGINS() {
	composer create-project -n -d $HOME/.terminus/plugins pantheon-systems/terminus-build-tools-plugin:$BUILD_TOOLS_VERSION
	composer create-project -n -d $HOME/.terminus/plugins pantheon-systems/terminus-secrets-plugin:^1
}

# Create Terminus plugins directory and install plugins if needed
if [ ! -d $HOME/.terminus/plugins ]
then
	mkdir -p $HOME/.terminus/plugins
	INSTALL_TERMINUS_PLUGINS
fi

# Stash the current time
CURRENT_TIMESTAMP=$(date +%s)
if [ ! -f $HOME/.terminus/plugins/last-updated.txt ]
then
	echo $CURRENT_TIMESTAMP > $HOME/.terminus/plugins/last-updated.txt
fi

# Stash the time Terminus plugins were last updated
TERMINUS_PLUGINS_UPDATED=$(cat $HOME/.terminus/plugins/last-updated.txt)

# Update Terminus plugins if they are more than 24 hours old
# Otherwise cached version will be used if they exist
if [ "$CURRRENT_TIMESTAMP - $TERMINUS_PLUGINS_UPDATED" -gt "86400" ]
then
	INSTALL_TERMINUS_PLUGINS
fi

#===============================
# End Install Terminus Plugins
#===============================

# Add a Git token for Composer
if [ -n "$GITHUB_TOKEN" ] ; then
  composer config --global github-oauth.github.com $GITHUB_TOKEN
fi

# Bail on errors
set +ex

# Authenticate with Terminis
terminus auth:login -n --machine-token="$TERMINUS_TOKEN"

# Disable host checking
touch $HOME/.ssh/config
echo "StrictHostKeyChecking no" >> "$HOME/.ssh/config"

# Configure Git credentials
git config --global user.email "$GIT_EMAIL"
git config --global user.name "Circle CI"
# Ignore file permissions.
git config --global core.fileMode false