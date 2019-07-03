"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = backstopConfig;

function untrailingSlashIt(str) {
  return str.replace(/\/$/, '');
}

function trailingSlashIt(str) {
  return str.replace(/\/$/, '') + '/';
}

function leadingSlashIt(str) {
  return '/' + str.replace(/^\//, '');
}

function backstopConfig() {
  const backstopDataDir = `backstop_data/`;
  const delayTime = 1500;
  const acceptableThreshold = 0.1;
  const referenceBaseUrl = process.env.LIVE_SITE_URL;
  const testBaseUrl = process.env.MULTIDEV_SITE_URL;
  const pathsToTest = [
    '/2017/05/21/hello-world/'
  ];
  const config = {
    'id': siteName,
    asyncCaptureLimit: 10,
    'viewports': [{
      'name': 'phone',
      'width': 320,
      'height': 480
    }, {
      'name': 'tablet',
      'width': 768,
      'height': 1024
    }, {
      'name': 'desktop',
      'width': 1920,
      'height': 1080
    }],
    'scenarios': [{
      'label': 'Homepage',
      'url': (0, trailingSlashIt)(testBaseUrl),
      'referenceUrl': (0, trailingSlashIt)(referenceBaseUrl),
      'hideSelectors': [],
      'selectors': ['document'],
      'readyEvent': null,
      'delay': delayTime,
      'misMatchThreshold': acceptableThreshold
    }],
    'paths': {
      'ci_report': `${backstopDataDir}/ci_report`,
      'json_report': `${backstopDataDir}/json_report`,
      'html_report': `${backstopDataDir}/html_report`,
      'bitmaps_reference': `${backstopDataDir}/bitmaps_reference`,
      'bitmaps_test': `${backstopDataDir}/bitmaps_test`,
      'compare_data': `${backstopDataDir}/bitmaps_test/compare.json`,
      'casper_scripts': `${backstopDataDir}/casper_scripts`,
      'engine_scripts': `${backstopDataDir}/engine_scripts`
    },
    'engine': 'puppeteer',
    'report': ['browser', 'json'],
    'casperFlags': [],
    'debug': false,
    'port': 3001
  };
  const scenarios = pathsToTest.map(function (path) {
    return {
      'label': path,
      'url': (0, untrailingSlashIt)(testBaseUrl) + (0, leadingSlashIt)(path),
      'referenceUrl': (0, untrailingSlashIt)(referenceBaseUrl) + (0, leadingSlashIt)(path),
      'hideSelectors': [],
      'selectors': ['document'],
      'readyEvent': null,
      'delay': delayTime,
      'misMatchThreshold': acceptableThreshold
    };
  });
  config.scenarios = config.scenarios.concat(scenarios);
  return config;
}