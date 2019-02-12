#!/bin/bash

if [[ ${CURRENT_BRANCH} != "master" && -z ${CI_PR_URL} ]];
then
  echo -e "CI will only deploy to Pantheon if on the master branch or creating a pull requests.\n"
  exit 0;
fi

# Bail if required environment varaibles are missing
if [ -z "$TERMINUS_SITE" ] || [ -z "$TERMINUS_ENV" ]
then
  echo 'No test site specified. Set TERMINUS_SITE and TERMINUS_ENV.'
  exit 1
fi

# Bail if no admin username/password are set
if [ -z "$ADMIN_USERNAME" ] || [ -z "$ADMIN_PASSWORD" ]
then
  echo "No WordPress credentials specified. Set ADMIN_USERNAME and ADMIN_PASSWORD."
  exit 1
fi

echo "::::::::::::::::::::::::::::::::::::::::::::::::"
echo "Behat test site: $TERMINUS_SITE.$TERMINUS_ENV"
echo "::::::::::::::::::::::::::::::::::::::::::::::::"
echo

# Delete the admin user if exists
terminus -n wp $TERMINUS_SITE.$TERMINUS_ENV -- user delete $ADMIN_USERNAME --yes

# Update WordPress database
terminus -n wp $TERMINUS_SITE.$TERMINUS_ENV -- core update-db

# Create a backup before running Behat tests
terminus -n backup:create $TERMINUS_SITE.$TERMINUS_ENV

# Create the desired admin user
terminus -n wp $TERMINUS_SITE.$TERMINUS_ENV -- user create $ADMIN_USERNAME no-reply@getpantheon.com --user_pass=$ADMIN_PASSWORD --role=administrator

# Confirm the admin user exists
terminus -n wp $TERMINUS_SITE.$TERMINUS_ENV -- user list --login=$ADMIN_USERNAME

# Clear site cache
terminus -n env:clear-cache $TERMINUS_SITE.$TERMINUS_ENV

# Dynamically set Behat configuration parameters
export BEHAT_PARAMS='{"extensions":{"Behat\\MinkExtension":{"base_url":"https://'$TERMINUS_ENV'-'$TERMINUS_SITE'.pantheonsite.io"},"PaulGibbs\\WordpressBehatExtension":{"site_url":"https://'$TERMINUS_ENV'-'$TERMINUS_SITE'.pantheonsite.io/wp","users":{"admin":{"username":"'$ADMIN_USERNAME'","password":"'$ADMIN_PASSWORD'"}},"wpcli":{"binary":"terminus -n wp '$TERMINUS_SITE'.'$TERMINUS_ENV' --"}}}}'

# Set Behat variables from environment variables
export RELOCATED_WP_ADMIN=TRUE

# Wake the multidev environment before running tests
terminus -n env:wake $TERMINUS_SITE.$TERMINUS_ENV

# Ping wp-cli to start ssh with the app server
terminus -n wp $TERMINUS_SITE.$TERMINUS_ENV -- cli version

# Verbose mode and exit on errors
set -ex

# Start headless Chrome
echo "\n Starting Chrome in headless mode ..."
google-chrome-unstable --disable-gpu --headless --remote-debugging-address=0.0.0.0 --remote-debugging-port=9222 --no-sandbox </dev/null &>/dev/null &

# Run the Behat tests
./vendor/bin/behat --config=tests/behat/behat-pantheon.yml --strict