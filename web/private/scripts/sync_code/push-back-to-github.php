<?php

/**
 * This script will attempt to push "lean" changes back upstream.
 */
$bindingDir = $_SERVER['HOME'];
$repositoryRoot = "$bindingDir/code";
$docRoot = "$repositoryRoot/" . $_SERVER['DOCROOT'];

print "Enter push-back-to-github. repository root is $repositoryRoot, docRoot is $docRoot\n";

$buildMetadataFile = "$repositoryRoot/build-metadata.json";
if (!file_exists($buildMetadataFile)) {
  print "Could not find build metadata file, $buildMetadataFile\n";
  return;
}
$buildMetadataFileContents = file_get_contents($buildMetadataFile);
$buildMetadata = json_decode($buildMetadataFileContents, true);

print "::::::::::::::::: Build Metadata :::::::::::::::::\n";
var_export($buildMetadata);
print "\n\n";

$privateFiles = "$bindingDir/files/private";
$gitHubSecretsFile = "$privateFiles/github-secrets.json";
$gitHubSecretsContents = file_get_contents($gitHubSecretsFile);
$gitHubSecrets = json_decode($gitHubSecretsContents, true);

print "::::::::::::::::: GitHub Secrets :::::::::::::::::\n";
var_export($gitHubSecrets);
print "\n\n";

// The remote repo to push to
$upstreamRepo = $gitHubSecrets['repo']['url'];

// The last commit made on the lean repo prior to creating the build artifacts
$fromSha = $buildMetadata['sha'];

// The name of the PR branch
$branch = $buildMetadata['ref'];

// The name of our new branch
$prBranch = "new-$branch";

// The commit to cherry-pick
$currentCommit = exec('git rev-parse HEAD');

// TODO: vet the contents of the commit for applicability first.
// If the commit is 'mixed', it must be rejected. Is there any
// way to recover from this? Maybe not.

print "::::::::::::::::: Info :::::::::::::::::\n";
print "We are going to check out $prBranch from $fromSha, then cherry-pick $currentCommit and push it back to $upstreamRepo\n";

// Create our new branch
passthru("git checkout -B $prBranch $fromSha");

// Cherry-pick the commit just made
passthru("git cherry-pick -Xthiers $currentCommit");

// Go back to the branch we were on before
passthru('git checkout -');

// Push the new branch back to Pantheon
passthru("git push $upstreamRepo $prBranch");
