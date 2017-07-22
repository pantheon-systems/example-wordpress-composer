#!/bin/bash

set -ex

# The section would be transferable to a DOCKERFILE
apt-get update

# Install needed apt packages
apt-get -y install git unzip jq

# Enable Composer parallel downloads
composer global require -n "hirak/prestissimo:^0.3"

# Install Terminus
/usr/bin/env COMPOSER_BIN_DIR=$HOME/bin composer --working-dir=$HOME require pantheon-systems/terminus "^1"
export PATH="${PATH}:${HOME}/terminus/bin"
terminus --version

# Install Terminus plugins
mkdir -p ~/.terminus/plugins
composer create-project -n -d ~/.terminus/plugins pantheon-systems/terminus-build-tools-plugin:$BUILD_TOOLS_VERSION
composer create-project -n -d ~/.terminus/plugins pantheon-systems/terminus-secrets-plugin:^1

# Commands below this line would not be transferable to a docker container

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