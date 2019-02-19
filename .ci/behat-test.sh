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
if [ -z "$BEHAT_ADMIN_USERNAME" ] || [ -z "$BEHAT_ADMIN_PASSWORD" ]
then
  echo "No WordPress credentials specified. Set BEHAT_ADMIN_USERNAME and BEHAT_ADMIN_PASSWORD."
  exit 1
fi

echo "::::::::::::::::::::::::::::::::::::::::::::::::"
echo "Behat test site: $TERMINUS_SITE.$TERMINUS_ENV"
echo "::::::::::::::::::::::::::::::::::::::::::::::::"
echo

# Check if an admin user with our desired username exists
BEHAT_ADMIN_USER_EXISTS=$(terminus -n wp ${TERMINUS_SITE}.${TERMINUS_ENV} -- user list --login=${BEHAT_ADMIN_USERNAME} --format=count)

# If so, delete the existing admin user
if [[ "$BEHAT_ADMIN_USER_EXISTS" == "1" ]]
then
  terminus -n wp $TERMINUS_SITE.$TERMINUS_ENV -- user delete $BEHAT_ADMIN_USERNAME --yes
fi

# Update WordPress database
terminus -n wp $TERMINUS_SITE.$TERMINUS_ENV -- core update-db

# Create a backup before running Behat tests
terminus -n backup:create $TERMINUS_SITE.$TERMINUS_ENV

# Create the desired admin user
terminus -n wp $TERMINUS_SITE.$TERMINUS_ENV -- user create $BEHAT_ADMIN_USERNAME $BEHAT_ADMIN_EMAIL --user_pass=$BEHAT_ADMIN_PASSWORD --role=administrator

# Confirm the admin user exists
terminus -n wp $TERMINUS_SITE.$TERMINUS_ENV -- user list --login=$BEHAT_ADMIN_USERNAME

# Clear site cache
terminus -n env:clear-cache $TERMINUS_SITE.$TERMINUS_ENV

# Dynamically set Behat configuration parameters
export BEHAT_PARAMS='{"extensions":{"Behat\\MinkExtension":{"base_url":"https://'$TERMINUS_ENV'-'$TERMINUS_SITE'.pantheonsite.io"},"PaulGibbs\\WordpressBehatExtension":{"site_url":"https://'$TERMINUS_ENV'-'$TERMINUS_SITE'.pantheonsite.io/wp","users":{"admin":{"username":"'$BEHAT_ADMIN_USERNAME'","password":"'$BEHAT_ADMIN_PASSWORD'"}},"wpcli":{"binary":"terminus -n wp '$TERMINUS_SITE'.'$TERMINUS_ENV' --"}}}}'

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
./vendor/bin/behat --config=tests/behat/behat-pantheon.yml --strict --colors  "$@"