#!/bin/bash

set -ex

# The section would be transferable to a DOCKERFILE
apt-get update

# Install needed apt packages
apt-get -y install git unzip jq

# Install Terminus
/usr/bin/env COMPOSER_BIN_DIR=$HOME/bin composer --working-dir=$HOME require pantheon-systems/terminus "^1"
terminus --version

# Install Terminus plugins
mkdir -p ~/.terminus/plugins
composer create-project -n -d ~/.terminus/plugins pantheon-systems/terminus-build-tools-plugin:$BUILD_TOOLS_VERSION
composer create-project -n -d ~/.terminus/plugins pantheon-systems/terminus-secrets-plugin:^1

# Commands below this line would not be transferable to a docker container

# Update path
export PATH="$PATH:~/bin:tests/scripts"

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