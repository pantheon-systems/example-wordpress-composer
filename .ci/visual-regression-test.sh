#!/bin/bash

# Variables
BUILD_DIR=$(pwd)
GITHUB_API_URL="https://api.github.com/repos/$CI_PROJECT_USERNAME/$CI_PROJECT_REPONAME"

# Check if we are NOT on the master branch and this is a PR
if [[ ${CI_BRANCH} != "master" && -z ${CI_PR_URL} ]];
then
  echo -e "\nVisual regression tests will only run if we are not on the master branch and making a pull request"
  exit 0;
fi

echo -e "\nProcessing pull request #$PR_NUMBER"

GIT_FILE_MODIFIED()
{
    # Stash list of changed files
    GIT_FILES_CHANGED="$(git diff origin/master --name-only)"

    while read -r changedFile; do
        if [[ "${changedFile}" == "$1" ]]
        then
            return 0;
        fi
    done <<< "$GIT_FILES_CHANGED"

    return 1;
}

LAST_GIT_COMMIT_MESSAGE=$(git log -1 --pretty=%B)

# Always run visual tests if "[vr]" is in the last commit message
if [[ ${LAST_GIT_COMMIT_MESSAGE} != *"[vr]"* ]]
then

    # Skip visual tests if there hasn't been a modification to composer.lock
    if ! GIT_FILE_MODIFIED 'composer.lock'
    then
        echo -e "\nSkipping visual regression tests since composer.lock has NOT changed"
        exit 0
    fi

    # Skip visual tests if has been a modification to composer.json
    if GIT_FILE_MODIFIED 'composer.json'
    then
        echo -e "\nSkipping visual regression tests since composer.json HAS changed"
        exit 0
    fi

else
    echo -e "\nRunning visual regression tests because the latest commit message demands it"
fi

# Ping the multidev environment to wake it from sleep
echo -e "\nPinging the ${TERMINUS_ENV} multidev environment to wake it from sleep..."
curl -I "$MULTIDEV_SITE_URL" >/dev/null

# Ping the live environment to wake it from sleep
echo -e "\nPinging the live environment to wake it from sleep..."
curl -I "$LIVE_SITE_URL" >/dev/null

# Check for custom backstop.json
if [ ! -f ./.ci/backstop.json ]; then
	# Create Backstop config file from template if needed
	echo -e "\nCloning backstop.default json to backstop.json..."
	cp .ci/backstop.default.json .ci/backstop.json
fi

# Dynamically set URLs in backstop.json
node .ci/dynamic-backstop-json-urls.js

# Backstop visual regression
echo -e "\nRunning backstop reference on ${LIVE_SITE_URL}..."
backstop reference --config=.ci/backstop.json

# Kill any zombie Chrome instances
pkill -f "(chrome)?(--headless)"

# Backstop test
echo -e "\nRunning backstop test on ${MULTIDEV_SITE_URL}..."
VISUAL_REGRESSION_RESULTS=$(backstop test --config=.ci/backstop.json || echo 'true')

echo "${VISUAL_REGRESSION_RESULTS}"

# Create the artifacts directory if needed
if [ ! -d "$ARTIFACTS_FULL_DIR" ]; then
  mkdir -p $ARTIFACTS_FULL_DIR
fi

export ARTIFACTS_DIR_URL="${CI_BUILD_URL}/artifacts/${CI_NODE_INDEX}/artifacts"

# Copy backstop_data files to ARTIFACTS_FULL_DIR
echo -e "\nCopying backstop_data files to $ARTIFACTS_FULL_DIR..."
rm -rf $ARTIFACTS_FULL_DIR/backstop_data
cp -r backstop_data $ARTIFACTS_FULL_DIR/

DIFF_IMAGE=$(find ./backstop_data -type f -name "*.png" | grep diff | grep desktop | head -n 1)

if [ ! -f $DIFF_IMAGE ]; then
	echo -e "\nDiff image file $DIFF_IMAGE not found!"
fi

DIFF_IMAGE_URL="$ARTIFACTS_DIR_URL/$DIFF_IMAGE"

DIFF_REPORT="$ARTIFACTS_FULL_DIR/backstop_data/html_report/index.html"

if [ ! -f $DIFF_REPORT ]; then
	echo -e "\nDiff report file $DIFF_REPORT not found!"
	exit 1
fi

DIFF_REPORT_URL="$ARTIFACTS_DIR_URL/backstop_data/html_report/index.html"

REPORT_LINK="[![Visual report]($DIFF_IMAGE_URL)]($DIFF_REPORT_URL)"

if [[ ${VISUAL_REGRESSION_RESULTS} == *"Mismatch errors found"* ]]
then
	# visual regression failed
	echo -e "\nVisual regression test failed!"
	PR_MESSAGE="Visual regression test failed! $REPORT_LINK"
else
	# visual regression passed
	REPORT_LINK="\n\nView the [visual regression test report]($DIFF_REPORT_URL)"
	echo -e "\n\nVisual regression test passed!"
	PR_MESSAGE="Visual regression test passed! $REPORT_LINK"
fi

# Post the image back to the pull request on GitHub
echo -e "\nPosting visual regression results back to PR #$PR_NUMBER "
curl -s -i -u "$CI_PROJECT_USERNAME:$GITHUB_TOKEN" -d "{\"body\": \"$PR_MESSAGE\"}" $GITHUB_API_URL/issues/$PR_NUMBER/comments > /dev/null

if [[ ${VISUAL_REGRESSION_RESULTS} == *"Mismatch errors found"* ]]
then
    exit 1
fi
