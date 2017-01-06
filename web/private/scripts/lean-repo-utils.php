<?php

/**
 * Read the secrets.json file
 */
function pantheon_get_secrets($bindingDir, $requiredKeys, $defaultValues) {
  $secretsFile = "$bindingDir/files/private/secrets.json";
  if (!file_exists($secretsFile)) {
    pantheon_raise_dashboard_error('Secrets file does not exist');
  }
  $secretsContents = file_get_contents($secretsFile);
  if (empty($secretsContents)) {
    pantheon_raise_dashboard_error('Could not read secrets file (or it is empty).');
  }
  $secrets = json_decode($secretsContents, 1);
  if (empty($secrets)) {
    pantheon_raise_dashboard_error('Could not parse json data in secrets file.');
  }
  $secrets += $defaultValues;
  $missing = array_diff($requiredKeys, array_keys($secrets));
  if (!empty($missing)) {
    die('Missing required keys in json secrets file: ' . implode(',', $missing) . '. Aborting!');
  }
  return $secrets;
}

/**
 * Function to report an error on the Pantheon dashboard
 *
 * Not supported; may stop working at any point in the future.
 */
function pantheon_raise_dashboard_error($reason = 'Uknown failure', $extended = FALSE) {
  // Make creative use of the error reporting API
  $data = array('file'=>'GitHub Integration',
                'line'=>'Error',
                'type'=>'error',
                'message'=>$reason);
  $params = http_build_query($data);
  $result = pantheon_curl('https://api.live.getpantheon.com/sites/self/environments/self/events?'. $params, NULL, 8443, 'POST');
  error_log("GitHub Integration failed - $reason");
  // Dump additional debug info into the error log
  if ($extended) {
    error_log(print_r($extended, 1));
  }
  die("GitHub Integration failed - $reason");
}
