#!/bin/bash

set -ex

BUILD_DIR=$(pwd)

# Add WordPress coding standards path to code sniffer
./vendor/bin/phpcs --config-set installed_paths $BUILD_DIR/vendor/wp-coding-standards/wpcs

# Run code sniff
./vendor/bin/phpcs ./web/wp-content

# Error if tests fail
if [ "$?" != 0 ]
then
	echo -e "\nPHPCS Failed. Please fix the error(s)."
	exit 1
fi

# Otherwise, tell the user good job
echo -e "\nPHPCS Passed. Good job!"