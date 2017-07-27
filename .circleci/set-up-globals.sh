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

#=======================================
# Start Install Terminus into ~/terminus
#=======================================
if [ ! -d "$HOME/terminus" ]
then
	# Clone terminus if it doesn't exist
	echo -e "Installing Terminus...\n"
	git clone --branch master git://github.com/pantheon-systems/terminus.git ~/terminus
	cd "$HOME/terminus"
	composer install
	cd -
else
	# Otherwise make sure terminus is up to date
	cd "$HOME/terminus"
	git pull
	composer install
	cd -
fi

#=======================================
# End Install Terminus into ~/terminus
#=======================================



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

#===============================
# End Install Terminus Plugins
#===============================

# Add a Git token for Composer
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
touch $HOME/.ssh/config
echo "StrictHostKeyChecking no" >> "$HOME/.ssh/config"

# Configure Git credentials
git config --global user.email "$GIT_EMAIL"
git config --global user.name "Circle CI"
# Ignore file permissions.
git config --global core.fileMode false