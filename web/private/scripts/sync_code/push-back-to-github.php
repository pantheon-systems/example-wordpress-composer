<?php

// This is only for multidev environments.
if (in_array($_ENV['PANTHEON_ENVIRONMENT'], ['dev', 'test', 'live'])) {
  return;
}

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
if (empty($buildMetadata)) {
  print "No data in build metadata\n";
  return;
}

print "::::::::::::::::: Build Metadata :::::::::::::::::\n";
var_export($buildMetadata);
print "\n\n";

$privateFiles = "$bindingDir/files/private";
$gitHubSecretsFile = "$privateFiles/github-secrets.json";
if (!file_exists($privateFiles)) {
  print "Could not find $gitHubSecretsFile\n";
  return;
}
$gitHubSecretsContents = file_get_contents($gitHubSecretsFile);
$gitHubSecrets = json_decode($gitHubSecretsContents, true);
if (empty($gitHubSecrets)) {
  print "No data in GitHub secrets\n";
  return;
}

print "::::::::::::::::: GitHub Secrets :::::::::::::::::\n";
var_export($gitHubSecrets);
print "\n\n";

// The remote repo to push to
$upstreamRepo = $buildMetadata['url'];
if (!empty($gitHubSecrets) && array_key_exists('token', $gitHubSecrets)) {
  $token = $gitHubSecrets['token'];
  $upstreamRepo = str_replace('git@github.com:', 'https://github.com/', $upstreamRepo);
  $upstreamRepo = str_replace('https://', "https://$token:x-oauth-basic@", $upstreamRepo);
}

// The last commit made on the lean repo prior to creating the build artifacts
$fromSha = $buildMetadata['sha'];

// The name of the PR branch
$branch = $buildMetadata['ref'];

// A working branch to make changes on
$workBranch = substr($currentCommit, 0, 5) . $branch;

// The commit to cherry-pick
$currentCommit = exec('git rev-parse HEAD');

print "::::::::::::::::: Info :::::::::::::::::\n";
print "We are going to check out $branch from $fromSha, then cherry-pick $currentCommit and push it back to {$buildMetadata['url']}\n";

// Create our new branch without switching to it. We start with
// '$fromSha' to avoid placing any build artifacts on our branch.
passthru("git -C $repositoryRoot branch -f $workBranch $fromSha");

$pantheonRepository = "file://$repositoryRoot";
$workRepository = "$bindingDir/tmp/scratchRepository";

// Clone our current repository -- but only take the current branch.
// We need a separate working tree because we do not want to alter the
// current repository, which is actively in use by the current multidev
// environment. Git requires a modifiable working tree to cherry-pick commits.
passthru("git clone $pantheonRepository --branch $workBranch --single-branch $workRepository");

// Use show | apply to do the equivalent of a cherry-pick
// between the two repositories.
exec("git -C $repositoryRoot show $currentCommit | git -c $workRepository apply -Xthiers", $output, $applyStatus);

// We're done with the work branch now.
passthru("git -C $repositoryRoot branch -D $workBranch");

// If the apply worked, then push the commit back to the light repository.
if ($applyStatus == 0) {
  // Get the sha commit hash of the remote GitHub branch, to see if
  // anyone has added any commits there since this environment was created.
  // This comes back as "sha   refs/heads/branch", so we'll trim the end.
  $remoteCommit = exec("git ls-remote $upstreamRepo $branch");
  $remoteCommit = preg_replace('/ .*/', '', $remoteCommit);

  // If the remote commit is the same as our base commit, then we will
  // push directly back to the original branch. If it does not match, then
  // we will push to a new branch name for the user to merge on GitHub.
  $targetBranch = $workBranch;
  if (($remoteCommit == $fromSha) && ($branch != 'master')) {
    $targetBranch = $branch;
  }

  // Push the new branch back to Pantheon
  passthru("git -C $workRepository push $upstreamRepo $workBranch:$targetBranch");
}

// We don't need the work branch or the second working repository any longer
passthru("rm -rf $workRepository");

// Post error to dashboard and exit if the merge fails.
if ($applyStatus != 0) {
  $message = "git apply failed with exit code $applyStatus.\n\n" . explode("\n", $output);
  pantheon_raise_dashboard_error($message, true);
}
