<?php

// Do nothing for test or live environments.
if (in_array($_ENV['PANTHEON_ENVIRONMENT'], ['test', 'live'])) {
  return;
}

include __DIR__ . '/../lean-repo-utils.php';

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

// The remote repo to push to
$upstreamRepo = $buildMetadata['url'];
$upstreamRepoWithCredentials = $upstreamRepo;
if (!empty($gitHubSecrets) && array_key_exists('token', $gitHubSecrets)) {
  $token = $gitHubSecrets['token'];
  $upstreamRepoWithCredentials = str_replace('git@github.com:', 'https://github.com/', $upstreamRepoWithCredentials);
  $upstreamRepoWithCredentials = str_replace('https://', "https://$token:x-oauth-basic@", $upstreamRepoWithCredentials);
}

// The last commit made on the lean repo prior to creating the build artifacts
$fromSha = $buildMetadata['sha'];

// The name of the PR branch
$branch = $buildMetadata['ref'];

// The commit to cherry-pick
$commitToSubmit = exec('git rev-parse HEAD');

// A working branch to make changes on
$targetBranch = $branch;

print "::::::::::::::::: Info :::::::::::::::::\n";
print "We are going to check out $branch from {$buildMetadata['url']}, branch from $fromSha and cherry-pick $commitToSubmit onto it\n";

$workRepository = "$bindingDir/tmp/scratchRepository";

// Temporary:
passthru("rm -rf $workRepository");

// Make a working clone of the GitHub branch. Clone just the branch
// and commit we need.
print "git clone $upstreamRepo --depth=1 --branch $branch --single-branch\n";
passthru("git clone $upstreamRepoWithCredentials --depth=1 --branch $branch --single-branch $workRepository 2>&1");

// If there have been extra commits, then unshallow the repository so that
// we can make a branch off of the commit this multidev was built from.
print "git -C $workRepository rev-parse HEAD\n";
$remoteHead = exec("git -C $workRepository rev-parse HEAD");
if ($remoteHead != $fromSha) {
  // TODO: If we had git 2.11.0, we could use --shallow-since with the date
  // from $buildMetadata['commit-date'] to get exactly the commits we need.
  // Until then, though, we will just `unshallow` the whole branch if there
  // is a conflicting commit.
  print "git -C $workRepository fetch --unshallow\n";
  passthru("git -C $workRepository fetch --unshallow 2>&1");
}

// If there are conflicting commits, or if this new commit is on the master
// branch, then we will work from and push to a branch with a different name.
// The user should then create a new PR on GitHub, and use the GitHub UI
// to resolve any conflicts (or clone the branch locally to do the same thing).
$createNewBranchReason = '';
if ($branch == 'master') {
  $createNewBranchReason = "the $branch branch cannot be pushed to directly";
}
elseif ($remoteHead != $fromSha) {
  $createNewBranchReason = "new conflicting commits (e.g. $remoteHead) were added to the upstream repository";
}
if (!empty($createNewBranchReason)) {
  // Warn that a new branch is being created.
  $targetBranch = substr($commitToSubmit, 0, 5) . $branch;
  print "Creating a new branch, '$targetBranch', because $createNewBranchReason.\n";
  print "git -C $workRepository checkout -B $targetBranch $fromSha\n";
  passthru("git -C $workRepository checkout -B $targetBranch $fromSha 2>&1");
}

// Use `git format-patch | git am` to do the equivalent of a cherry-pick
// between the two repositories. This should not fail, as we are applying
// our changes on top of the commit this branch was built from.
print "git -C $repositoryRoot format-patch --stdout {$commitToSubmit}~ | git -C $workRepository am\n";
exec("git -C $repositoryRoot format-patch --stdout {$commitToSubmit}~ | git -C $workRepository am 2>&1", $output, $applyStatus);

// Make sure that HEAD changed after 'git apply'
$appliedCommit = exec('git -C $workRepository rev-parse HEAD');

// Seatbelts: we expect this should only happen if $applyStatus != 0
if ($appliedCommit == $remoteHead) {
  print "'git apply' did not add any commits. Status code: $applyStatus\n";
  print "Output:\n";
  print implode("\n", $output) . "\n";
}

// If the apply worked, then push the commit back to the light repository.
if (($applyStatus == 0) && ($appliedCommit != $remoteHead)) {
  // Push the new branch back to Pantheon
  print "git -C $workRepository push $upstreamRepo $targetBranch\n";
  passthru("git -C $workRepository push $upstreamRepoWithCredentials $targetBranch 2>&1");

  // TODO: If a new branch was created, it would be cool to use the GitHub API
  // to create a new PR. If there is an existing PR (i.e. branch not master),
  // it would also be cool to cross-reference the new PR to the old PR. The trouble
  // here is converting the branch name to a PR number.
}

// Throw out the working repository.
passthru("rm -rf $workRepository");

// Post error to dashboard and exit if the merge fails.
if ($applyStatus != 0) {
  $message = "git apply failed with exit code $applyStatus.\n\n" . implode("\n", $output);
  pantheon_raise_dashboard_error($message, true);
}
