#!/bin/bash

set -ex

#==================================================
# The section would be transferable to a DOCKERFILE
#==================================================

# Update current apt packages
apt-get update

# Install needed apt packages
apt-get -y install git unzip jq

#=========================================================================
# Commands below this line would not be transferable to a docker container
#=========================================================================

# Enable Composer parallel downloads
composer global require -n "hirak/prestissimo:^0.3"

# Install Terminus
if [ ! -d $HOME/terminus ]
then
	# Clone terminus if it doesn't exist
	echo -e "Installing Terminus...\n"
	git clone --branch master git://github.com/pantheon-systems/terminus.git $HOME/terminus
	cd $HOME/terminus
	composer install
	cd -
else
	# Otherwise make sure terminus is up to date
	cd $HOME/terminus
	git pull
	composer install
	cd -
fi

#export PATH="${PATH}:${HOME}/terminus/bin:${HOME}/bin"

echo 'export PATH=$PATH:$HOME/bin:$HOME/terminus/bin' >> $BASH_ENV
source $BASH_ENV 

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