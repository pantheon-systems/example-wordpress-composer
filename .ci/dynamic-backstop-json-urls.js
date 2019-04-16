// Require the node file system
var fs = require('fs');
// Stash the directory where the script was started from
var rootPath = process.cwd();
// Get the contents of the backstop.json template
var fileContents = require(rootPath + '/.ci/backstop.default.json');

// Relative URLs don't start with http
function isRelativeURL(url) {
  return !url.startsWith('http');
}

// Stash live URL, removing any trailing slash
var liveURL = process.env.LIVE_SITE_URL.replace(/\/$/, "");

// Stash multidev URL, removing any trailing slash
var multidevURL = process.env.MULTIDEV_SITE_URL.replace(/\/$/, "");

// Loop through all scrnarios in the template
var newScenarios = fileContents.scenarios.map(function (scenario) {

  // If the url of the scenario is empty
  if (scenario.url.legth == 0) {
    // Set it to the multidev URL
    scenario.url = multidevURL;
    // If the url of the scenario is relative
  } else if (isRelativeURL(scenario.url)) {
    // Prepend the multidev URL
    scenario.url = multidevURL + scenario.referenceUrl;
  }

  // If the url of the reference scenario is empty
  if (scenario.referenceUrl.length == 0) {
    // Set it to the live URL
    scenario.referenceUrl = liveURL;
    // If the url of the reference scenario is relative
  } else if (isRelativeURL(scenario.referenceUrl)) {
    // Prepend the live URL
    scenario.referenceUrl = liveURL + scenario.referenceUrl;
  }

  // Return the updated scenario
  return scenario;
});

// Update the scenarios from the template with the new
// version containing the actual URLs
fileContents.scenarios = newScenarios;

// Write the backstop.json file
fs.writeFileSync(rootPath + '/.ci/backstop.json', JSON.stringify(fileContents, null, 2), function (err) {
  if (err) return console.log(err);
  console.log(rootPath + '/.ci/backstop.json created successfully!');
});
